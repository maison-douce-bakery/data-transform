-- One row per branch and business date that has sold receipts or refunds (is_sold definition).
-- Receipt totals and refunds are aggregated separately at this grain, then joined on
-- the key list, so nothing is counted twice. Gross amounts stay original; refunds are separate columns.
with sales as (

    select * from {{ ref('fct_sales') }}
    where is_sold

),

receipts_daily as (

    select
        branch_id,
        business_date,
        count(*) as order_count,
        count(customer_id) as customer_order_count,
        sum(line_count) as line_count,
        sum(gross_amount) as gross_amount,
        sum(discount_amount) as discount_amount,
        sum(net_amount) as net_amount,
        sum(tax_amount) as tax_amount,
        sum(total_amount) as revenue_amount,
        sum(refund_amount) as refund_amount_by_sale_date
    from sales
    group by branch_id, business_date

),

refunds_daily as (

    select
        branch_id,
        business_date,
        count(*) as return_line_count,
        sum(refund_amount) as refund_amount_by_refund_date
    from {{ ref('fct_returns') }}
    where is_sold
    group by branch_id, business_date

),

keys as (

    select branch_id, business_date from receipts_daily
    union
    select branch_id, business_date from refunds_daily

),

branches as (

    select branch_sk, branch_id, branch_name from {{ ref('dim_branches') }}

)

select
    b.branch_sk,
    k.branch_id,
    b.branch_name,
    {{ date_sk('k.business_date') }} as date_sk,
    k.business_date,
    coalesce(r.order_count, 0) as order_count,
    coalesce(r.customer_order_count, 0) as customer_order_count,
    coalesce(r.line_count, 0) as line_count,
    coalesce(r.gross_amount, 0) as gross_amount,
    coalesce(r.discount_amount, 0) as discount_amount,
    coalesce(r.net_amount, 0) as net_amount,
    coalesce(r.tax_amount, 0) as tax_amount,
    coalesce(r.revenue_amount, 0) as revenue_amount,
    coalesce(r.refund_amount_by_sale_date, 0) as refund_amount_by_sale_date,
    coalesce(r.revenue_amount, 0) - coalesce(r.refund_amount_by_sale_date, 0) as net_revenue_amount_by_sale_date,
    coalesce(f.return_line_count, 0) as return_line_count,
    coalesce(f.refund_amount_by_refund_date, 0) as refund_amount_by_refund_date,
    coalesce(r.revenue_amount, 0) - coalesce(f.refund_amount_by_refund_date, 0) as net_revenue_amount_by_refund_date,
    coalesce(r.revenue_amount, 0) / nullif(r.order_count, 0) as average_order_value
from keys as k
left join receipts_daily as r
    on k.branch_id is not distinct from r.branch_id and k.business_date = r.business_date
left join refunds_daily as f
    on k.branch_id is not distinct from f.branch_id and k.business_date = f.business_date
left join branches as b on k.branch_id = b.branch_id
