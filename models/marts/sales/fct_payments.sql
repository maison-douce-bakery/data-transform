-- One row per non-deleted payment of a non-deleted sale. A sale can have several attempts.
-- collected_amount is the payment amount when the money was received (CAPTURED or REFUNDED), else 0.
with payments as (

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
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__payments') }}
    where not is_deleted

),

receipts as (

    select
        sale_id,
        receipt_number,
        branch_id,
        customer_id,
        cashier_id,
        channel,
        sale_status,
        opened_at,
        completed_at,
        sold_at,
        business_date,
        is_completed,
        is_sold,
        gross_amount,
        discount_amount,
        net_amount,
        tax_amount,
        total_amount
    from {{ ref('int_sales__receipts') }}

),

branches as (

    select branch_sk, branch_id from {{ ref('dim_branches') }}

),

customers as (

    select customer_sk, customer_id, valid_from, valid_to from {{ ref('dim_customers') }}

)

select
    p.payment_id,
    p.sale_id,
    b.branch_sk,
    r.branch_id,
    c.customer_sk,
    r.customer_id,
    {{ date_sk(business_date('p.paid_at')) }} as date_sk,
    {{ business_date('p.paid_at') }} as business_date,
    p.paid_at,
    {{ date_sk('r.business_date') }} as sale_date_sk,
    r.business_date as sale_date,
    r.sale_status,
    r.is_sold,
    p.payment_method,
    p.status as payment_status,
    p.status in ('CAPTURED', 'REFUNDED') as is_collected,
    p.currency_code,
    p.amount as payment_amount,
    case when p.status in ('CAPTURED', 'REFUNDED') then p.amount else 0 end as collected_amount,
    p.provider_reference
from payments as p
inner join receipts as r on p.sale_id = r.sale_id
left join branches as b on r.branch_id = b.branch_id
left join customers as c
    on r.customer_id = c.customer_id
    and r.sold_at >= c.valid_from
    and r.sold_at < c.valid_to
