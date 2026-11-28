-- Atomic inventory ledger, one row per non-deleted stock movement.
-- Branch and lot keys come from their dimensions, so a missing branch or lot gives a NULL key, not a hash of NULL.
-- signed_quantity is signed (positive adds stock). Value is signed too and NULL when the cost is unknown.
with movements as (

    select
        stock_movement_id,
        branch_id,
        stock_item_id,
        inventory_lot_id,
        movement_type,
        signed_quantity,
        uom_id,
        occurred_at,
        business_date,
        source_type,
        source_id,
        created_by,
        expected_sign,
        is_sign_consistent,
        item_type,
        item_base_uom_id,
        is_item_base_uom,
        lot_code,
        manufactured_date,
        received_date,
        expiry_date,
        lot_matches_item,
        movement_unit_cost,
        lot_unit_cost,
        valuation_unit_cost,
        cost_basis
    from {{ ref('int_inventory__movements_signed') }}

)

select
    m.stock_movement_id,
    br.branch_sk,
    m.branch_id,
    {{ dbt_utils.generate_surrogate_key(['m.stock_item_id']) }} as stock_item_sk,
    m.stock_item_id,
    lot.inventory_lot_sk,
    m.inventory_lot_id,
    {{ dbt_utils.generate_surrogate_key(['m.uom_id']) }} as uom_sk,
    m.uom_id,
    {{ date_sk('m.business_date') }} as date_sk,
    m.business_date,
    m.occurred_at,
    e.employee_sk,
    m.created_by as employee_id,
    m.movement_type,
    m.signed_quantity,
    m.source_type,
    m.source_id,
    m.is_sign_consistent,
    m.movement_unit_cost,
    m.lot_unit_cost,
    m.valuation_unit_cost as unit_cost,
    m.cost_basis,
    m.signed_quantity * m.valuation_unit_cost as signed_value,
    m.valuation_unit_cost is null as has_unknown_cost
from movements as m
left join {{ ref('dim_branches') }} as br on m.branch_id = br.branch_id
left join {{ ref('dim_inventory_lots') }} as lot on m.inventory_lot_id = lot.inventory_lot_id
left join {{ ref('dim_employees') }} as e
    on m.created_by = e.employee_id
    and m.occurred_at >= e.valid_from
    and m.occurred_at < e.valid_to
