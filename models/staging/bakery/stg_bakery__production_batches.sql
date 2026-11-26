with source as (

    select * from {{ source('bakery', 'production_batches') }}

),

renamed as (

    select
        production_batch_id,
        batch_number,
        branch_id,
        product_id,
        recipe_id,
        planned_quantity,
        produced_quantity,
        uom_id,
        status,
        started_at,
        completed_at,
        produced_by,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
