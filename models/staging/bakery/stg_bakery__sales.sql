with source as (

    select * from {{ source('bakery', 'sales') }}

),

renamed as (

    select
        sale_id,
        receipt_number,
        branch_id,
        customer_id,
        cashier_id,
        channel,
        status,
        opened_at,
        completed_at,
        subtotal,
        discount_total,
        tax_total,
        total_amount,
        idempotency_key,
        notes,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
