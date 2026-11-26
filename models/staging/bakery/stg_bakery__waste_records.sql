with source as (

    select * from {{ source('bakery', 'waste_records') }}

),

renamed as (

    select
        waste_record_id,
        branch_id,
        stock_item_id,
        inventory_lot_id,
        quantity,
        uom_id,
        reason_code,
        recorded_at,
        recorded_by,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
