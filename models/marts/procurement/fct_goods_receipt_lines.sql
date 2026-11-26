with receipt_lines as (

    select * from {{ ref('stg_bakery__goods_receipt_items') }} where not is_deleted

),

receipts as (

    select * from {{ ref('stg_bakery__goods_receipts') }} where not is_deleted

),

po_lines as (

    select purchase_order_item_id, purchase_order_id, uom_id, expected_unit_cost
    from {{ ref('stg_bakery__purchase_order_items') }}
    where not is_deleted

),

purchase_orders as (

    select purchase_order_id, po_number
    from {{ ref('stg_bakery__purchase_orders') }}
    where not is_deleted

),

joined as (

    select
        l.goods_receipt_item_id,
        l.goods_receipt_id,
        r.receipt_number,
        r.supplier_invoice_number,
        r.supplier_id,
        r.branch_id,
        r.received_by,
        r.received_at,
        {{ business_date('r.received_at') }} as business_date,
        l.stock_item_id,
        l.uom_id,
        l.inventory_lot_id,
        l.received_quantity,
        l.actual_unit_cost,
        l.received_quantity * l.actual_unit_cost as actual_line_value,
        r.purchase_order_id,
        po.po_number,
        l.purchase_order_item_id,
        pl.expected_unit_cost,
        l.uom_id = pl.uom_id as units_match_po_line
    from receipt_lines as l
    inner join receipts as r on l.goods_receipt_id = r.goods_receipt_id
    left join po_lines as pl on l.purchase_order_item_id = pl.purchase_order_item_id
    left join purchase_orders as po on r.purchase_order_id = po.purchase_order_id

),

final as (

    select
        j.goods_receipt_item_id,
        j.goods_receipt_id,
        j.receipt_number,
        j.supplier_invoice_number,
        s.supplier_sk,
        j.supplier_id,
        b.branch_sk,
        j.branch_id,
        e.employee_sk as received_by_employee_sk,
        j.received_by as received_by_employee_id,
        i.stock_item_sk,
        j.stock_item_id,
        u.uom_sk,
        j.uom_id,
        j.inventory_lot_id,
        {{ date_sk('j.business_date') }} as date_sk,
        j.received_at,
        j.business_date,
        j.received_quantity,
        j.actual_unit_cost,
        j.actual_line_value,
        j.actual_unit_cost is not null as is_actual_price_known,
        j.purchase_order_id,
        j.po_number,
        j.purchase_order_item_id,
        j.purchase_order_id is not null as is_linked_to_po,
        j.purchase_order_item_id is not null as is_linked_to_po_line,
        j.units_match_po_line,
        j.expected_unit_cost,
        -- Unit-price difference only when the unit equals the ordered unit and both prices are known.
        case
            when j.units_match_po_line then j.actual_unit_cost - j.expected_unit_cost
        end as unit_cost_variance_amount
    from joined as j
    left join {{ ref('dim_suppliers') }} as s on j.supplier_id = s.supplier_id
    left join {{ ref('dim_branches') }} as b on j.branch_id = b.branch_id
    left join {{ ref('dim_stock_items') }} as i on j.stock_item_id = i.stock_item_id
    left join {{ ref('dim_units_of_measure') }} as u on j.uom_id = u.uom_id
    left join {{ ref('dim_employees') }} as e
        on j.received_by = e.employee_id
        and j.received_at >= e.valid_from
        and j.received_at < e.valid_to

)

select * from final
