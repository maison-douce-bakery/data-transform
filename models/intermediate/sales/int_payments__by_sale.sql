-- Receipt grain: payment attempts summed per sale, so joining it to receipts cannot fan out.
-- Collected money is CAPTURED, plus REFUNDED (it was received before the refund mark).
-- FAILED and PENDING are never collected. The refund ledger is the return lines, not the payment status.
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

)

select
    sale_id,
    count(*) as payment_count,
    count(*) filter (where status = 'FAILED') as failed_payment_count,
    sum(amount) filter (where status in ('CAPTURED', 'REFUNDED')) as collected_amount,
    sum(amount) filter (where status = 'CAPTURED') as captured_amount,
    sum(amount) filter (where status = 'REFUNDED') as refunded_payment_amount,
    sum(amount) filter (where status = 'PENDING') as pending_amount,
    sum(amount) filter (where status = 'FAILED') as failed_amount,
    string_agg(distinct payment_method, ',' order by payment_method)
        filter (where status in ('CAPTURED', 'REFUNDED')) as payment_methods
from payments
group by sale_id
