with source as (

    select * from {{ source('bakery', 'recipe_items') }}

),

renamed as (

    select
        recipe_item_id,
        recipe_id,
        stock_item_id,
        quantity,
        uom_id,
        is_optional,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
