-- Loyalty transaction grain with the customer's point balance after each movement.
-- Order is occurred_at, then id. EARN +, REDEEM -, ADJUST +/-, EXPIRE - are already signed in points_delta.
with transactions as (

    select
        loyalty_transaction_id,
        customer_id,
        sale_id,
        transaction_type,
        points_delta,
        occurred_at,
        idempotency_key,
        notes,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__loyalty_transactions') }}
    where not is_deleted

)

select
    loyalty_transaction_id,
    customer_id,
    sale_id,
    transaction_type,
    points_delta,
    occurred_at,
    sum(points_delta) over (
        partition by customer_id
        order by occurred_at, loyalty_transaction_id
        rows between unbounded preceding and current row
    ) as balance_after
from transactions
