-- One row per non-deleted sale line. Dimensions are resolved as of the sale time. Returns are summed
-- per original line before joining, so amounts stay on the original-sale basis.
with lines as (

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

returns as (

    select
        sale_item_id,
        sum(returned_quantity) as returned_quantity,
        sum(refund_amount) as refund_amount
    from {{ ref('int_returns__completed_lines') }}
    group by sale_item_id

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

)

select
    l.sale_item_id,
    l.sale_id,
    b.branch_sk,
    l.branch_id,
    c.customer_sk,
    l.customer_id,
    p.product_sk,
    l.product_id,
    u.uom_sk,
    l.uom_id,
    {{ date_sk('l.business_date') }} as date_sk,
    l.business_date,
    l.sold_at,
    l.sale_status,
    l.is_completed,
    l.is_sold,
    l.quantity,
    l.unit_price,
    l.gross_amount,
    l.discount_amount,
    l.net_amount,
    coalesce(r.returned_quantity, 0) as returned_quantity,
    l.quantity - coalesce(r.returned_quantity, 0) as net_quantity,
    coalesce(r.refund_amount, 0) as refund_amount,
    l.net_amount - coalesce(r.refund_amount, 0) as net_after_refund_amount
from lines as l
left join returns as r on l.sale_item_id = r.sale_item_id
left join branches as b on l.branch_id = b.branch_id
left join units as u on l.uom_id = u.uom_id
left join customers as c
    on l.customer_id = c.customer_id
    and l.sold_at >= c.valid_from
    and l.sold_at < c.valid_to
left join products as p
    on l.product_id = p.product_id
    and l.sold_at >= p.valid_from
    and l.sold_at < p.valid_to
