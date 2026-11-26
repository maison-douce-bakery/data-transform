-- One row per current, non-deleted customer, including customers with no purchases. Orders use the
-- is_sold definition, matched by customer_id across dimension versions (original amounts, refunds
-- separate). Loyalty balance is in points. Walk-in sales have no customer and are not in this report.
with customers as (

    select customer_sk, customer_id, customer_code, full_name, joined_at, marketing_consent, is_active
    from {{ ref('dim_customers') }}
    where is_current and not is_deleted

),

orders as (

    select
        customer_id,
        count(*) as order_count,
        sum(gross_amount) as gross_amount,
        sum(discount_amount) as discount_amount,
        sum(total_amount) as revenue_amount,
        sum(refund_amount) as refund_amount,
        min(business_date) as first_purchase_date,
        max(business_date) as last_purchase_date
    from {{ ref('fct_sales') }}
    where is_sold and customer_id is not null
    group by customer_id

),

loyalty as (

    select
        customer_id,
        sum(points_delta) as loyalty_points_balance,
        sum(points_delta) filter (where transaction_type = 'EARN') as points_earned,
        -sum(points_delta) filter (where transaction_type = 'REDEEM') as points_redeemed,
        max(occurred_at) as last_loyalty_at
    from {{ ref('fct_loyalty_transactions') }}
    group by customer_id

)

select
    c.customer_sk,
    c.customer_id,
    c.customer_code,
    c.full_name,
    c.joined_at,
    c.marketing_consent,
    c.is_active,
    coalesce(o.order_count, 0) as order_count,
    coalesce(o.gross_amount, 0) as gross_amount,
    coalesce(o.discount_amount, 0) as discount_amount,
    coalesce(o.revenue_amount, 0) as revenue_amount,
    coalesce(o.refund_amount, 0) as refund_amount,
    coalesce(o.revenue_amount, 0) - coalesce(o.refund_amount, 0) as net_after_refund_amount,
    coalesce(o.revenue_amount, 0) / nullif(o.order_count, 0) as average_order_value,
    o.first_purchase_date,
    o.last_purchase_date,
    coalesce(l.loyalty_points_balance, 0) as loyalty_points_balance,
    coalesce(l.points_earned, 0) as points_earned,
    coalesce(l.points_redeemed, 0) as points_redeemed,
    l.last_loyalty_at
from customers as c
left join orders as o on c.customer_id = o.customer_id
left join loyalty as l on c.customer_id = l.customer_id
