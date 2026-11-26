with source as (

    select * from {{ source('bakery', 'payments') }}

),

renamed as (

    select
        payment_id,
        sale_id,
        payment_method,
        amount,
        currency_code,
        status,
        paid_at,
        provider_reference,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
