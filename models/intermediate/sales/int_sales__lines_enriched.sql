-- Sale line grain. Receipt attributes are copied for slicing only; receipt amounts are not repeated
-- here, so nothing can be summed twice. Lines of deleted sales and deleted lines are excluded.
-- The line discount already contains the promotion discount plus the allocated points redemption.
with items as (

    select * from {{ ref('stg_bakery__sale_items') }}
    where not is_deleted

),

receipts as (

    select * from {{ ref('int_sales__receipts') }}

)

select
    i.sale_item_id,
    i.sale_id,
    r.receipt_number,
    r.branch_id,
    r.customer_id,
    r.cashier_id,
    r.channel,
    r.sale_status,
    r.is_completed,
    r.is_sold,
    r.sold_at,
    r.business_date,
    i.product_id,
    i.uom_id,
    i.product_name_snapshot,
    i.quantity,
    i.unit_price,
    i.quantity * i.unit_price as gross_amount,
    i.discount_amount,
    i.line_total as net_amount
from items as i
inner join receipts as r on i.sale_id = r.sale_id
