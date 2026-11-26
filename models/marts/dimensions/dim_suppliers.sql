select
    {{ dbt_utils.generate_surrogate_key(['supplier_id']) }} as supplier_sk,
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
    is_deleted
from {{ ref('stg_bakery__suppliers') }}
