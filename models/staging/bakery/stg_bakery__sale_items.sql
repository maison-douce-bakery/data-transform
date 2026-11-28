select
    sale_item_id,
    sale_id,
    product_id,
    quantity,
    uom_id,
    product_name_snapshot,
    unit_price,
    discount_amount,
    line_total,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'sale_items') }}
