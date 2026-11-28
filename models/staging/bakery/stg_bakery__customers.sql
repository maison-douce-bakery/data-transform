select
    customer_id,
    customer_code,
    full_name,
    phone,
    email,
    date_of_birth,
    joined_at,
    marketing_consent,
    is_active,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'customers') }}
