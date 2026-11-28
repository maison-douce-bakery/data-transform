-- Receipt grain. Soft-deleted sales are excluded here, so everything built on it is clean.
with sales as (

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
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__sales') }}
    where not is_deleted

)

select
    sale_id,
    receipt_number,
    branch_id,
    customer_id,
    cashier_id,
    channel,
    status as sale_status,
    opened_at,
    completed_at,
    -- Event time of the sale: completion, or opening when it never completed
    coalesce(completed_at, opened_at) as sold_at,
    {{ business_date('coalesce(completed_at, opened_at)') }} as business_date,
    status = 'COMPLETED' as is_completed,
    status in ('COMPLETED', 'PARTIALLY_REFUNDED', 'REFUNDED') as is_sold,
    subtotal as gross_amount,
    discount_total as discount_amount,
    subtotal - discount_total as net_amount,
    tax_total as tax_amount,
    total_amount
from sales
