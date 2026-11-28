select
    goods_receipt_item_id,
    goods_receipt_id,
    purchase_order_item_id,
    stock_item_id,
    inventory_lot_id,
    received_quantity,
    uom_id,
    actual_unit_cost,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'goods_receipt_items') }}
