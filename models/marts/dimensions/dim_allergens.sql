select
    {{ dbt_utils.generate_surrogate_key(['allergen_id']) }} as allergen_sk,
    allergen_id,
    allergen_code,
    allergen_name,
    is_deleted
from {{ ref('stg_bakery__allergens') }}
