select
    promotion_id,
    promotion_code,
    promotion_name,
    promotion_type,
    discount_value,
    minimum_order_amount,
    starts_at,
    ends_at,
    max_uses,
    is_active,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'promotions') }}
