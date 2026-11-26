with source as (

    select * from {{ source('bakery', 'allergens') }}

),

renamed as (

    select
        allergen_id,
        allergen_code,
        allergen_name,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
