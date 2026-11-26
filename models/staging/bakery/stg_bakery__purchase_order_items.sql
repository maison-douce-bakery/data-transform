with source as (

    select * from {{ source('bakery', 'purchase_order_items') }}

),

renamed as (

    select
        purchase_order_item_id,
        purchase_order_id,
        stock_item_id,
        ordered_quantity,
        uom_id,
        expected_unit_cost,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
