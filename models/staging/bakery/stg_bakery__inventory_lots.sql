with source as (

    select * from {{ source('bakery', 'inventory_lots') }}

),

renamed as (

    select
        inventory_lot_id,
        stock_item_id,
        lot_code,
        supplier_lot_code,
        goods_receipt_id,
        manufactured_at,
        received_at,
        expires_at,
        unit_cost,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
