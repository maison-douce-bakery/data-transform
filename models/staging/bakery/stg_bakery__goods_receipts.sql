select
    goods_receipt_id,
    receipt_number,
    purchase_order_id,
    supplier_id,
    branch_id,
    received_at,
    received_by,
    supplier_invoice_number,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'goods_receipts') }}
