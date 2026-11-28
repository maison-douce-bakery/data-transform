-- One row per non-deleted promotion application on a non-deleted sale. discount_amount is the
-- amount actually given, not the configured value. Points redemption has no row here, so the sum
-- per sale can be lower than fct_sales.discount_amount.
with applied as (

    select
        sale_promotion_id,
        sale_id,
        promotion_id,
        discount_amount,
        coupon_code,
        applied_at,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__sale_promotions') }}
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

promotions as (

    select promotion_sk, promotion_id from {{ ref('dim_promotions') }}

),

branches as (

    select branch_sk, branch_id from {{ ref('dim_branches') }}

),

customers as (

    select customer_sk, customer_id, valid_from, valid_to from {{ ref('dim_customers') }}

)

select
    a.sale_promotion_id,
    a.sale_id,
    pr.promotion_sk,
    a.promotion_id,
    b.branch_sk,
    r.branch_id,
    c.customer_sk,
    r.customer_id,
    {{ date_sk(business_date('a.applied_at')) }} as date_sk,
    {{ business_date('a.applied_at') }} as business_date,
    a.applied_at,
    r.sale_status,
    r.is_sold,
    a.coupon_code,
    a.discount_amount
from applied as a
inner join receipts as r on a.sale_id = r.sale_id
left join promotions as pr on a.promotion_id = pr.promotion_id
left join branches as b on r.branch_id = b.branch_id
left join customers as c
    on r.customer_id = c.customer_id
    and r.sold_at >= c.valid_from
    and r.sold_at < c.valid_to
