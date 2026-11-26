with source as (

    select * from {{ source('bakery', 'employees') }}

),

renamed as (

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
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
