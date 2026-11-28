select
    branch_id,
    branch_code,
    branch_name,
    address,
    phone,
    timezone,
    opening_date,
    is_active,
    notes,
    created_at as branch_created_at,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'branches') }}
