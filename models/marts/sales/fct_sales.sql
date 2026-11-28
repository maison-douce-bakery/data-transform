-- One row per non-deleted sale. Payments, lines and returns are aggregated to the receipt
-- before joining, and the as-of dimension joins match at most one version, so no fan-out.
with receipts as (

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

line_counts as (

    select sale_id, count(*) as line_count
    from {{ ref('int_sales__lines_enriched') }}
    group by sale_id

),

payments as (

    select
        sale_id,
        payment_count,
        failed_payment_count,
        collected_amount,
        captured_amount,
        refunded_payment_amount,
        pending_amount,
        failed_amount,
        payment_methods
    from {{ ref('int_payments__by_sale') }}

),

refunds as (

    select
        sale_id,
        count(*) as returned_line_count,
        sum(refund_amount) as refund_amount
    from {{ ref('int_returns__completed_lines') }}
    group by sale_id

),

branches as (

    select branch_sk, branch_id from {{ ref('dim_branches') }}

),

customers as (

    select customer_sk, customer_id, valid_from, valid_to from {{ ref('dim_customers') }}

),

employees as (

    select employee_sk, employee_id, valid_from, valid_to from {{ ref('dim_employees') }}

)

select
    r.sale_id,
    r.receipt_number,
    b.branch_sk,
    r.branch_id,
    c.customer_sk,
    r.customer_id,
    e.employee_sk,
    r.cashier_id as employee_id,
    {{ date_sk('r.business_date') }} as date_sk,
    r.business_date,
    r.sold_at,
    r.opened_at,
    r.completed_at,
    r.channel,
    r.sale_status,
    r.is_completed,
    r.is_sold,
    coalesce(lc.line_count, 0) as line_count,
    r.gross_amount,
    r.discount_amount,
    r.net_amount,
    r.tax_amount,
    r.total_amount,
    coalesce(p.payment_count, 0) as payment_count,
    coalesce(p.failed_payment_count, 0) as failed_payment_count,
    coalesce(p.collected_amount, 0) as collected_amount,
    coalesce(p.pending_amount, 0) as pending_amount,
    coalesce(p.failed_amount, 0) as failed_amount,
    p.payment_methods,
    coalesce(f.returned_line_count, 0) as returned_line_count,
    coalesce(f.refund_amount, 0) as refund_amount,
    r.total_amount - coalesce(f.refund_amount, 0) as net_after_refund_amount
from receipts as r
left join line_counts as lc on r.sale_id = lc.sale_id
left join payments as p on r.sale_id = p.sale_id
left join refunds as f on r.sale_id = f.sale_id
left join branches as b on r.branch_id = b.branch_id
left join customers as c
    on r.customer_id = c.customer_id
    and r.sold_at >= c.valid_from
    and r.sold_at < c.valid_to
left join employees as e
    on r.cashier_id = e.employee_id
    and r.sold_at >= e.valid_from
    and r.sold_at < e.valid_to
