with source as (

    select * from {{ source('bakery', 'products') }}

),

renamed as (

    select
        product_id,
        sku,
        product_name,
        category_id,
        product_type,
        sell_uom_id,
        stock_item_id,
        description,
        ingredient_summary,
        unit_price,
        is_active,
        available_from,
        available_to,
        created_at as product_created_at,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
