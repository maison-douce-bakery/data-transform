-- SCD2 dimension over snap_employees. Join facts as of event time:
-- event_ts >= valid_from and event_ts < valid_to.
with versions as (

    select
        employee_id,
        branch_id,
        employee_code,
        full_name,
        role_name,
        phone,
        hired_on,
        terminated_on,
        is_active,
        created_at,
        updated_at,
        is_deleted,
        deleted_at,
        scd_id,
        snapshot_updated_at,
        valid_from,
        valid_to,
        {{ scd2_valid_from('employee_id') }} as version_valid_from
    from {{ ref('snap_employees') }}

)

select
    {{ scd2_surrogate_key('employee_id', 'version_valid_from') }} as employee_sk,
    employee_id,
    branch_id,
    employee_code,
    full_name,
    role_name,
    phone,
    hired_on,
    terminated_on,
    is_active,
    version_valid_from as valid_from,
    valid_to,
    valid_to = {{ scd_end_of_time() }} as is_current,
    is_deleted
from versions
