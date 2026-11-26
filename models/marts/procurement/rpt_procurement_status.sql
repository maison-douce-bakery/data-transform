with lines as (

    select * from {{ ref('fct_purchase_order_lines') }}

),

dates as (

    select
        *,
        {{ business_date('current_timestamp') }} as as_of_date,
        {{ business_date('first_received_at') }} as first_received_date,
        {{ business_date('last_received_at') }} as last_received_date
    from lines

),

classified as (

    select
        *,
        case
            when receipt_line_count = 0 then 'NOT_RECEIVED'
            when not units_comparable then 'UNITS_NOT_COMPARABLE'
            when received_quantity_in_ordered_uom > ordered_quantity then 'OVER_RECEIVED'
            when received_quantity_in_ordered_uom = ordered_quantity then 'FULLY_RECEIVED'
            else 'PARTIALLY_RECEIVED'
        end as receipt_status
    from dates

),

final as (

    select
        c.purchase_order_item_id,
        c.purchase_order_id,
        c.po_number,
        c.po_status,
        c.supplier_sk,
        c.supplier_id,
        s.supplier_code,
        s.supplier_name,
        c.branch_sk,
        c.branch_id,
        c.stock_item_sk,
        c.stock_item_id,
        i.stock_item_name,
        c.uom_sk,
        c.uom_id,
        u.uom_code,
        c.date_sk,
        c.business_date,
        c.expected_date_sk,
        c.expected_date,
        c.ordered_quantity,
        c.received_quantity_in_ordered_uom,
        c.units_comparable,
        c.receipt_status,
        -- Over/short exists only when every receipt line is in the ordered unit (positive = over, negative = short).
        case
            when c.units_comparable and not c.is_cancelled
                then c.received_quantity_in_ordered_uom - c.ordered_quantity
        end as over_short_quantity,
        c.open_quantity,
        c.expected_unit_cost,
        c.expected_line_value,
        c.received_value,
        c.receipt_line_count,
        c.other_uom_receipt_line_count,
        c.first_received_date,
        c.last_received_date,
        c.as_of_date,
        -- Open = sent to the supplier and still waiting for goods.
        (c.po_status in ('SENT', 'PARTIALLY_RECEIVED') and c.receipt_status in ('NOT_RECEIVED', 'PARTIALLY_RECEIVED')) as is_open,
        case
            when c.po_status in ('SENT', 'PARTIALLY_RECEIVED') and c.receipt_status in ('NOT_RECEIVED', 'PARTIALLY_RECEIVED')
                then c.as_of_date - c.business_date
        end as days_open,
        (
            c.po_status in ('SENT', 'PARTIALLY_RECEIVED')
            and c.receipt_status in ('NOT_RECEIVED', 'PARTIALLY_RECEIVED')
            and c.expected_date is not null
            and c.as_of_date > c.expected_date
        ) as is_overdue,
        case
            when c.po_status in ('SENT', 'PARTIALLY_RECEIVED')
                and c.receipt_status in ('NOT_RECEIVED', 'PARTIALLY_RECEIVED')
                and c.expected_date is not null
                then greatest(c.as_of_date - c.expected_date, 0)
        end as days_overdue,
        -- Days between the expected date and the last receipt, once the line is complete (negative = early).
        case
            when c.receipt_status in ('FULLY_RECEIVED', 'OVER_RECEIVED') and c.expected_date is not null
                then c.last_received_date - c.expected_date
        end as days_late_at_completion,
        -- PO header says RECEIVED but this line is not complete, or the reverse.
        (
            (c.po_status = 'RECEIVED' and c.receipt_status in ('NOT_RECEIVED', 'PARTIALLY_RECEIVED'))
            or (c.po_status in ('DRAFT', 'CANCELLED') and c.receipt_line_count > 0)
        ) as is_status_inconsistent
    from classified as c
    left join {{ ref('dim_suppliers') }} as s on c.supplier_sk = s.supplier_sk
    left join {{ ref('dim_stock_items') }} as i on c.stock_item_sk = i.stock_item_sk
    left join {{ ref('dim_units_of_measure') }} as u on c.uom_sk = u.uom_sk

)

select * from final
