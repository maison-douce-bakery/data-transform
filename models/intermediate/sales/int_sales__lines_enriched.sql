-- Sale line grain. Receipt attributes are copied for slicing only; receipt amounts are not repeated
-- here, so nothing can be summed twice. Lines of deleted sales and deleted lines are excluded.
-- The line discount already contains the promotion discount plus the allocated points redemption.
with items as (

    select
        sale_item_id,
        sale_id,
        product_id,
        quantity,
        uom_id,
        product_name_snapshot,
        unit_price,
        discount_amount,
        line_total,
        notes,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__sale_items') }}
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
