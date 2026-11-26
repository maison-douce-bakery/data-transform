-- Lot dimension (type 1), one row per inventory lot. Whether a lot is expired depends on the report
-- date, so expiry flags live in the reports, not here. Unknown unit cost stays NULL.
with lots as (

    select * from {{ ref('stg_bakery__inventory_lots') }}

),

output_lots as (

    select distinct inventory_lot_id
    from {{ ref('stg_bakery__stock_movements') }}
    where movement_type = 'PRODUCTION_OUTPUT' and not is_deleted

)

select
    {{ dbt_utils.generate_surrogate_key(['l.inventory_lot_id']) }} as inventory_lot_sk,
    l.inventory_lot_id,
    {{ dbt_utils.generate_surrogate_key(['l.stock_item_id']) }} as stock_item_sk,
    l.stock_item_id,
    l.lot_code,
    l.supplier_lot_code,
    l.goods_receipt_id,
    l.manufactured_at as manufactured_date,
    l.received_at as received_date,
    l.expires_at as expiry_date,
    l.expires_at is not null as has_expiry,
    l.unit_cost,
    l.unit_cost is null as has_unknown_cost,
    case
        when l.goods_receipt_id is not null then 'GOODS_RECEIPT'
        when o.inventory_lot_id is not null then 'PRODUCTION'
        else 'OTHER'
    end as lot_source,
    l.is_deleted
from lots as l
left join output_lots as o on l.inventory_lot_id = o.inventory_lot_id
