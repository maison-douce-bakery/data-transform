-- One row per non-deleted loyalty transaction, with the customer's running point balance.
-- Customer version is resolved as of the transaction time.
with transactions as (

    select
        loyalty_transaction_id,
        customer_id,
        sale_id,
        transaction_type,
        points_delta,
        occurred_at,
        balance_after
    from {{ ref('int_loyalty__running_balance') }}

),

customers as (

    select customer_sk, customer_id, valid_from, valid_to from {{ ref('dim_customers') }}

)

select
    t.loyalty_transaction_id,
    c.customer_sk,
    t.customer_id,
    t.sale_id,
    {{ date_sk(business_date('t.occurred_at')) }} as date_sk,
    {{ business_date('t.occurred_at') }} as business_date,
    t.occurred_at,
    t.transaction_type,
    t.points_delta,
    t.balance_after as points_balance_after
from transactions as t
left join customers as c
    on t.customer_id = c.customer_id
    and t.occurred_at >= c.valid_from
    and t.occurred_at < c.valid_to
