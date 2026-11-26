with source as (

    select * from {{ source('bakery', 'shifts') }}

),

renamed as (

    select
        shift_id,
        branch_id,
        employee_id,
        shift_code,
        opened_at,
        closed_at,
        opening_cash,
        counted_cash,
        status,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
