select
    {{ dbt_utils.generate_surrogate_key(['s.stock_item_id']) }} as stock_item_sk,
    s.stock_item_id,
    s.stock_item_code,
    s.stock_item_name,
    s.item_type,
    s.base_uom_id,
    u.uom_code as base_uom_code,
    u.uom_name as base_uom_name,
    s.track_lot,
    s.track_expiry,
    s.reorder_level as reorder_level_quantity,
    s.is_active,
    s.is_deleted
from {{ ref('stg_bakery__stock_items') }} as s
left join {{ ref('stg_bakery__units_of_measure') }} as u on s.base_uom_id = u.uom_id
