select
    {{ dbt_utils.generate_surrogate_key(['uom_id']) }} as uom_sk,
    uom_id,
    uom_code,
    uom_name,
    dimension,
    is_base_unit,
    is_deleted
from {{ ref('stg_bakery__units_of_measure') }}
