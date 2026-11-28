select
    return_item_id,
    return_id,
    sale_item_id,
    quantity,
    restockable,
    refund_amount,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'return_items') }}
