select
    loyalty_transaction_id,
    customer_id,
    sale_id,
    transaction_type,
    points_delta,
    occurred_at,
    idempotency_key,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'loyalty_transactions') }}
