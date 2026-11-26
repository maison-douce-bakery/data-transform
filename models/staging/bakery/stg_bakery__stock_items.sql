with source as (

    select * from {{ source('bakery', 'stock_items') }}

),

renamed as (

    select
        stock_item_id,
        stock_item_code,
        stock_item_name,
        item_type,
        base_uom_id,
        track_lot,
        track_expiry,
        reorder_level,
        is_active,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
