with source as (

    select * from {{ source('bakery', 'product_categories') }}

),

renamed as (

    select
        category_id,
        category_code,
        category_name,
        parent_category_id,
        description,
        is_active,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
