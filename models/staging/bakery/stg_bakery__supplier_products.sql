with source as (

    select * from {{ source('bakery', 'supplier_products') }}

),

renamed as (

    select
        supplier_product_id,
        supplier_id,
        stock_item_id,
        supplier_sku,
        brand_name,
        purchase_uom_id,
        pack_size,
        pack_uom_id,
        last_known_unit_cost,
        currency_code,
        is_active,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
