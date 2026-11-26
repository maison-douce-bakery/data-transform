with source as (

    select * from {{ source('bakery', 'product_allergens') }}

),

renamed as (

    select
        product_id,
        allergen_id,
        is_confirmed,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
