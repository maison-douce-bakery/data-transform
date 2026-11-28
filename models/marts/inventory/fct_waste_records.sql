-- Waste records, one row per non-deleted waste record. quantity is positive, in the stock item unit.
-- Value = quantity x lot unit cost, NULL when the lot cost is unknown (never 0). Record count, quantity
-- and value are different measures: do not equate them.
with waste as (

    select
        waste_record_id,
        branch_id,
        stock_item_id,
        inventory_lot_id,
        quantity,
        uom_id,
        reason_code,
        recorded_at,
        recorded_by,
        notes,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__waste_records') }}
    where not is_deleted

),

lots as (

    select inventory_lot_id, unit_cost as lot_unit_cost, expires_at
    from {{ ref('stg_bakery__inventory_lots') }}

),

-- The matching negative WASTE movement of each record (waste_record_id is the movement source_id).
movements as (

    select
        source_id as waste_record_id,
        count(*) as movement_count,
        sum(-signed_quantity) as movement_quantity
    from {{ ref('int_inventory__movements_signed') }}
    where movement_type = 'WASTE' and source_type = 'WASTE_RECORD'
    group by source_id

)

select
    w.waste_record_id,
    br.branch_sk,
    w.branch_id,
    {{ dbt_utils.generate_surrogate_key(['w.stock_item_id']) }} as stock_item_sk,
    w.stock_item_id,
    dl.inventory_lot_sk,
    w.inventory_lot_id,
    {{ dbt_utils.generate_surrogate_key(['w.uom_id']) }} as uom_sk,
    w.uom_id,
    e.employee_sk,
    w.recorded_by as employee_id,
    {{ date_sk(business_date('w.recorded_at')) }} as date_sk,
    {{ business_date('w.recorded_at') }} as business_date,
    w.recorded_at,
    w.reason_code,
    w.quantity,
    l.lot_unit_cost as unit_cost,
    w.quantity * l.lot_unit_cost as waste_value,
    l.lot_unit_cost is null as has_unknown_cost,
    w.inventory_lot_id is null as has_no_lot,
    m.waste_record_id is not null as has_stock_movement,
    coalesce(m.movement_quantity = w.quantity, false) as is_movement_quantity_matching
from waste as w
left join lots as l on w.inventory_lot_id = l.inventory_lot_id
left join {{ ref('dim_branches') }} as br on w.branch_id = br.branch_id
left join {{ ref('dim_inventory_lots') }} as dl on w.inventory_lot_id = dl.inventory_lot_id
left join movements as m on w.waste_record_id = m.waste_record_id
left join {{ ref('dim_employees') }} as e
    on w.recorded_by = e.employee_id
    and w.recorded_at >= e.valid_from
    and w.recorded_at < e.valid_to
