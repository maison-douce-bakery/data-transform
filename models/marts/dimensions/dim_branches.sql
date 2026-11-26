select
    {{ dbt_utils.generate_surrogate_key(['branch_id']) }} as branch_sk,
    branch_id,
    branch_code,
    branch_name,
    address,
    phone,
    timezone,
    opening_date,
    is_active,
    is_deleted
from {{ ref('stg_bakery__branches') }}
