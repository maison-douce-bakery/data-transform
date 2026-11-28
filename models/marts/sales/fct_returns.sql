-- One row per line of a COMPLETED, non-deleted return, dated at the return time (refund date).
-- Branch, customer, product, uom and the original sale come from the original sale line; customer,
-- product and processing employee versions are resolved as of the return time.
with return_lines as (

    select
        return_item_id,
        return_id,
        return_number,
        sale_id,
        sale_item_id,
        processed_by,
        returned_at,
        business_date,
        sale_date,
        reason,
        returned_quantity,
        refund_amount,
        restockable,
        is_sale_consistent
    from {{ ref('int_returns__completed_lines') }}

),

sale_lines as (

    select
        sale_item_id,
        sale_id,
        receipt_number,
        branch_id,
        customer_id,
        cashier_id,
        channel,
        sale_status,
        is_completed,
        is_sold,
        sold_at,
        business_date,
        product_id,
        uom_id,
        product_name_snapshot,
        quantity,
        unit_price,
        gross_amount,
        discount_amount,
        net_amount
    from {{ ref('int_sales__lines_enriched') }}

),

branches as (

    select branch_sk, branch_id from {{ ref('dim_branches') }}

),

units as (

    select uom_sk, uom_id from {{ ref('dim_units_of_measure') }}

),

customers as (

    select customer_sk, customer_id, valid_from, valid_to from {{ ref('dim_customers') }}

),

products as (

    select product_sk, product_id, valid_from, valid_to from {{ ref('dim_products') }}

),

employees as (

    select employee_sk, employee_id, valid_from, valid_to from {{ ref('dim_employees') }}

)

select
    rl.return_item_id,
    rl.return_id,
    rl.return_number,
    rl.sale_id,
    rl.sale_item_id,
    b.branch_sk,
    sl.branch_id,
    c.customer_sk,
    sl.customer_id,
    p.product_sk,
    sl.product_id,
    u.uom_sk,
    sl.uom_id,
    e.employee_sk,
    rl.processed_by as employee_id,
    {{ date_sk('rl.business_date') }} as date_sk,
    rl.business_date,
    rl.returned_at,
    {{ date_sk('rl.sale_date') }} as sale_date_sk,
    rl.sale_date,
    sl.sale_status,
    sl.is_sold,
    rl.reason,
    rl.restockable,
    rl.returned_quantity,
    rl.refund_amount
from return_lines as rl
inner join sale_lines as sl on rl.sale_item_id = sl.sale_item_id
left join branches as b on sl.branch_id = b.branch_id
left join units as u on sl.uom_id = u.uom_id
left join customers as c
    on sl.customer_id = c.customer_id
    and rl.returned_at >= c.valid_from
    and rl.returned_at < c.valid_to
left join products as p
    on sl.product_id = p.product_id
    and rl.returned_at >= p.valid_from
    and rl.returned_at < p.valid_to
left join employees as e
    on rl.processed_by = e.employee_id
    and rl.returned_at >= e.valid_from
    and rl.returned_at < e.valid_to
