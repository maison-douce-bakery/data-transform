-- SCD2 dimension over snap_customers. Join facts as of event time:
-- event_ts >= valid_from and event_ts < valid_to.
with versions as (

    select
        *,
        {{ scd2_valid_from('customer_id') }} as version_valid_from
    from {{ ref('snap_customers') }}

)

select
    {{ scd2_surrogate_key('customer_id', 'version_valid_from') }} as customer_sk,
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
    version_valid_from as valid_from,
    valid_to,
    valid_to = {{ scd_end_of_time() }} as is_current,
    is_deleted
from versions
