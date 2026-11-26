-- Type 1. effective_from / effective_to are the promotion's own natural window (source starts_at / ends_at).
select
    {{ dbt_utils.generate_surrogate_key(['promotion_id']) }} as promotion_sk,
    promotion_id,
    promotion_code,
    promotion_name,
    promotion_type,
    discount_value,
    minimum_order_amount,
    starts_at as effective_from,
    ends_at as effective_to,
    max_uses,
    is_active,
    is_deleted
from {{ ref('stg_bakery__promotions') }}
