-- Non-deleted stock movements with lot and item attributes and the business date.
-- signed_quantity (the source quantity_delta) already carries the sign; expected_sign is what the movement type implies,
-- so a mismatch is flagged instead of silently corrected (the signed quantity is the truth).
with movements as (

    select
        *,
        case
            when movement_type in ('PURCHASE_RECEIPT', 'PRODUCTION_OUTPUT', 'RETURN_IN', 'ADJUSTMENT_IN', 'TRANSFER_IN') then 1
            when movement_type in ('PRODUCTION_CONSUMPTION', 'SALE', 'WASTE', 'ADJUSTMENT_OUT', 'TRANSFER_OUT') then -1
        end as expected_sign
    from {{ ref('stg_bakery__stock_movements') }}
    where not is_deleted

),

lots as (

    select
        inventory_lot_id,
        stock_item_id as lot_stock_item_id,
        lot_code,
        manufactured_at as manufactured_date,
        received_at as received_date,
        expires_at as expiry_date,
        unit_cost as lot_unit_cost
    from {{ ref('stg_bakery__inventory_lots') }}

),

items as (

    select stock_item_id, item_type, base_uom_id
    from {{ ref('stg_bakery__stock_items') }}

)

select
    m.stock_movement_id,
    m.branch_id,
    m.stock_item_id,
    m.inventory_lot_id,
    m.movement_type,
    m.quantity_delta as signed_quantity,
    m.uom_id,
    m.occurred_at,
    {{ business_date('m.occurred_at') }} as business_date,
    m.source_type,
    m.source_id,
    m.created_by,
    m.expected_sign,
    sign(m.quantity_delta)::int = m.expected_sign as is_sign_consistent,
    i.item_type,
    i.base_uom_id as item_base_uom_id,
    m.uom_id = i.base_uom_id as is_item_base_uom,
    l.lot_code,
    l.manufactured_date,
    l.received_date,
    l.expiry_date,
    (m.inventory_lot_id is null or l.lot_stock_item_id = m.stock_item_id) as lot_matches_item,
    m.unit_cost as movement_unit_cost,
    l.lot_unit_cost,
    -- Lot cost wins; the cost recorded on the movement is only a fallback. Unknown stays NULL, never 0.
    coalesce(l.lot_unit_cost, m.unit_cost) as valuation_unit_cost,
    case
        when l.lot_unit_cost is not null then 'LOT'
        when m.unit_cost is not null then 'MOVEMENT'
    end as cost_basis
from movements as m
left join lots as l on m.inventory_lot_id = l.inventory_lot_id
left join items as i on m.stock_item_id = i.stock_item_id
