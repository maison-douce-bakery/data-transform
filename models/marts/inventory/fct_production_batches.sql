-- Production batches, one row per non-deleted batch.
-- Planned and actual quantity are in the batch unit. A missing actual stays NULL (it is not 0) and
-- only COMPLETED batches count as output. Cost is materials only (no labour or overhead): not profit.
-- Dimension keys are as of the batch event time: start, else completion, else creation.
with batches as (

    select
        production_batch_id,
        batch_number,
        branch_id,
        product_id,
        recipe_id,
        planned_quantity,
        produced_quantity,
        uom_id,
        status,
        started_at,
        completed_at,
        produced_by,
        notes,
        created_at,
        updated_at,
        is_deleted,
        deleted_at,
        coalesce(started_at, completed_at, created_at) as event_at
    from {{ ref('stg_bakery__production_batches') }}
    where not is_deleted

),

costs as (

    select
        production_batch_id,
        consumption_line_count,
        unknown_cost_line_count,
        has_unknown_cost,
        known_material_cost,
        material_cost,
        unit_cost
    from {{ ref('int_production__batch_costs') }}

),

effective_recipes as (

    select
        b.production_batch_id,
        p.recipe_id as effective_recipe_id
    from batches as b
    inner join {{ ref('int_production__recipe_periods') }} as p
        on b.product_id = p.product_id
        and {{ business_date('b.event_at') }} >= p.period_start
        and {{ business_date('b.event_at') }} < p.period_end

),

final as (

    select
        b.production_batch_id,
        b.batch_number,
        br.branch_sk,
        b.branch_id,
        pr.product_sk,
        b.product_id,
        rec.recipe_sk,
        b.recipe_id,
        erec.recipe_sk as effective_recipe_sk,
        er.effective_recipe_id,
        -- NULL when no recipe version is effective on the batch date.
        case
            when er.effective_recipe_id is not null then b.recipe_id is not distinct from er.effective_recipe_id
        end as uses_effective_recipe,
        {{ dbt_utils.generate_surrogate_key(['b.uom_id']) }} as uom_sk,
        b.uom_id,
        e.employee_sk,
        b.produced_by as employee_id,
        {{ date_sk(business_date('b.event_at')) }} as date_sk,
        {{ business_date('b.event_at') }} as business_date,
        b.status,
        b.started_at,
        b.completed_at,
        case
            when b.started_at is not null and b.completed_at is not null and b.completed_at >= b.started_at
                then extract(epoch from b.completed_at - b.started_at) / 60.0
        end as duration_minutes,
        b.planned_quantity,
        b.produced_quantity as actual_quantity,
        -- Output exists only for completed batches; planned, cancelled or running batches have none.
        case when b.status = 'COMPLETED' then b.produced_quantity end as output_quantity,
        b.status = 'COMPLETED' and b.produced_quantity is null as is_missing_actual,
        -- Same set for numerator and denominator: completed, with both actual and planned known.
        (b.status = 'COMPLETED' and b.produced_quantity is not null and b.planned_quantity > 0) as is_attainment_comparable,
        case
            when b.status = 'COMPLETED' and b.produced_quantity is not null and b.planned_quantity > 0
                then b.produced_quantity / b.planned_quantity
        end as attainment_ratio,
        c.consumption_line_count,
        c.unknown_cost_line_count,
        coalesce(c.has_unknown_cost, true) as has_unknown_cost,
        c.known_material_cost,
        c.material_cost,
        case when b.status = 'COMPLETED' then c.unit_cost end as unit_cost
    from batches as b
    left join costs as c on b.production_batch_id = c.production_batch_id
    left join effective_recipes as er on b.production_batch_id = er.production_batch_id
    left join {{ ref('dim_branches') }} as br on b.branch_id = br.branch_id
    left join {{ ref('dim_recipes') }} as rec on b.recipe_id = rec.recipe_id
    left join {{ ref('dim_recipes') }} as erec on er.effective_recipe_id = erec.recipe_id
    left join {{ ref('dim_products') }} as pr
        on b.product_id = pr.product_id
        and b.event_at >= pr.valid_from
        and b.event_at < pr.valid_to
    left join {{ ref('dim_employees') }} as e
        on b.produced_by = e.employee_id
        and b.event_at >= e.valid_from
        and b.event_at < e.valid_to

)

select
    production_batch_id,
    batch_number,
    branch_sk,
    branch_id,
    product_sk,
    product_id,
    recipe_sk,
    recipe_id,
    effective_recipe_sk,
    effective_recipe_id,
    uses_effective_recipe,
    uom_sk,
    uom_id,
    employee_sk,
    employee_id,
    date_sk,
    business_date,
    status,
    started_at,
    completed_at,
    duration_minutes,
    planned_quantity,
    actual_quantity,
    output_quantity,
    is_missing_actual,
    is_attainment_comparable,
    attainment_ratio,
    consumption_line_count,
    unknown_cost_line_count,
    has_unknown_cost,
    known_material_cost,
    material_cost,
    unit_cost
from final
