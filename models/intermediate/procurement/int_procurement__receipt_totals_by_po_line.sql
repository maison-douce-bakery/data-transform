-- Receipt lines rolled up to PO line grain. Aggregating here, before any join to the PO
-- line, is what prevents fan-out when a line is received in several deliveries.
with receipt_lines as (

    select
        gri.purchase_order_item_id,
        gri.uom_id,
        gri.received_quantity,
        gri.actual_unit_cost,
        gr.received_at
    from {{ ref('stg_bakery__goods_receipt_items') }} as gri
    inner join {{ ref('stg_bakery__goods_receipts') }} as gr
        on gri.goods_receipt_id = gr.goods_receipt_id
    where not gri.is_deleted
        and not gr.is_deleted
        and gri.purchase_order_item_id is not null

),

po_lines as (

    select purchase_order_item_id, uom_id as ordered_uom_id
    from {{ ref('stg_bakery__purchase_order_items') }}
    where not is_deleted

),

totals as (

    select
        p.purchase_order_item_id,
        count(*) as receipt_line_count,
        -- Only quantities in the ordered unit are summed; other units are counted, never added.
        coalesce(sum(r.received_quantity) filter (where r.uom_id = p.ordered_uom_id), 0) as received_quantity_in_ordered_uom,
        count(*) filter (where r.uom_id <> p.ordered_uom_id) as other_uom_receipt_line_count,
        -- Money does not depend on the unit, so every receipt line counts toward the value.
        sum(r.received_quantity * r.actual_unit_cost) as received_value,
        count(*) filter (where r.actual_unit_cost is null) as unpriced_receipt_line_count,
        min(r.received_at) as first_received_at,
        max(r.received_at) as last_received_at
    from receipt_lines as r
    inner join po_lines as p on r.purchase_order_item_id = p.purchase_order_item_id
    group by p.purchase_order_item_id

)

select
    purchase_order_item_id,
    receipt_line_count,
    received_quantity_in_ordered_uom,
    other_uom_receipt_line_count,
    received_value,
    unpriced_receipt_line_count,
    first_received_at,
    last_received_at
from totals
