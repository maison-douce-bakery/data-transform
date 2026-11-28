select
    purchase_order_id,
    po_number,
    supplier_id,
    branch_id,
    ordered_at,
    expected_at,
    status,
    currency_code,
    notes,
    created_by,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'purchase_orders') }}
