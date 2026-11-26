select
    product_id,
    sku,
    product_name,
    product_type,
    unit_price,
    is_active
from {{ source('bakery', 'products') }}
