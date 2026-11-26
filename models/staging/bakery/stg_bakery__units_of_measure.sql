with source as (

    select * from {{ source('bakery', 'units_of_measure') }}

),

renamed as (

    select
        uom_id,
        uom_code,
        uom_name,
        dimension,
        is_base_unit,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
