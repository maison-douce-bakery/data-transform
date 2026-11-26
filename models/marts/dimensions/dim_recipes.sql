-- Recipe version dimension (type 1). effective_from / effective_to are the version's declared effective window
-- as dates, half-open [effective_from, effective_to); effective_to is 9999-12-31 when open-ended, never NULL.
-- The window is as declared: overlaps are flagged here and resolved in int_production__recipe_periods.
with recipes as (

    select * from {{ ref('stg_bakery__recipes') }}

),

overlapping as (

    select distinct a.recipe_id
    from recipes as a
    inner join recipes as b
        on a.product_id = b.product_id
        and a.recipe_id <> b.recipe_id
        and a.effective_from <= coalesce(b.effective_to, date '9999-12-31')
        and b.effective_from <= coalesce(a.effective_to, date '9999-12-31')
    where not a.is_deleted and not b.is_deleted

),

current_products as (

    select product_id, sku, product_name
    from {{ ref('dim_products') }}
    where is_current

)

select
    {{ dbt_utils.generate_surrogate_key(['r.recipe_id']) }} as recipe_sk,
    r.recipe_id,
    r.product_id,
    p.sku as product_sku,
    p.product_name,
    r.recipe_version,
    r.yield_quantity as standard_output_quantity,
    {{ dbt_utils.generate_surrogate_key(['r.yield_uom_id']) }} as standard_output_uom_sk,
    r.yield_uom_id as standard_output_uom_id,
    r.effective_from as effective_from,
    case
        when r.effective_to is null then date '9999-12-31'
        else r.effective_to + 1
    end as effective_to,
    o.recipe_id is not null as has_overlap,
    r.is_active,
    r.is_deleted
from recipes as r
left join current_products as p on r.product_id = p.product_id
left join overlapping as o on r.recipe_id = o.recipe_id
