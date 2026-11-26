with source as (

    select * from {{ source('bakery', 'cash_movements') }}

),

renamed as (

    select
        cash_movement_id,
        shift_id,
        movement_type,
        amount,
        occurred_at,
        sale_id,
        recorded_by,
        description,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
