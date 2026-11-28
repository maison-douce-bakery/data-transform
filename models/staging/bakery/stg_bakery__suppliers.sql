select
    supplier_id,
    supplier_code,
    supplier_name,
    supplier_type,
    country_code,
    website,
    phone,
    email,
    address,
    is_active,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'suppliers') }}
