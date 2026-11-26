with source as (

    select * from {{ source('bakery', 'returns') }}

),

renamed as (

    select
        return_id,
        return_number,
        sale_id,
        processed_by,
        returned_at,
        reason,
        status,
        refund_total,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
