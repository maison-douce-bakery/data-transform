-- One row per business date, branch, product and unit of measure (is_sold definition, original sale
-- date basis). Quantities of different units of measure are never added together. Product name and
-- category are the current version (history is not tracked for these here).
with items as (

    select * from {{ ref('fct_sale_items') }}
    where is_sold

),

daily as (

    select
        business_date,
        branch_id,
        product_id,
        uom_id,
        count(distinct sale_id) as order_count,
        count(*) as line_count,
        sum(quantity) as sold_quantity,
        sum(gross_amount) as gross_amount,
        sum(discount_amount) as discount_amount,
        sum(net_amount) as net_amount,
        sum(returned_quantity) as returned_quantity,
        sum(refund_amount) as refund_amount
    from items
    group by business_date, branch_id, product_id, uom_id

),

branches as (

    select branch_sk, branch_id, branch_name from {{ ref('dim_branches') }}

),

products as (

    select product_id, sku, product_name, product_type, category_name
    from {{ ref('dim_products') }}
    where is_current

),

units as (

    select uom_id, uom_code from {{ ref('dim_units_of_measure') }}

)

select
    {{ date_sk('d.business_date') }} as date_sk,
    d.business_date,
    b.branch_sk,
    d.branch_id,
    b.branch_name,
    d.product_id,
    p.sku,
    p.product_name,
    p.product_type,
    p.category_name,
    d.uom_id,
    u.uom_code,
    d.order_count,
    d.line_count,
    d.sold_quantity,
    d.gross_amount,
    d.discount_amount,
    d.net_amount,
    d.returned_quantity,
    d.sold_quantity - d.returned_quantity as net_quantity,
    d.refund_amount,
    d.net_amount - d.refund_amount as net_after_refund_amount
from daily as d
left join branches as b on d.branch_id = b.branch_id
left join products as p on d.product_id = p.product_id
left join units as u on d.uom_id = u.uom_id
