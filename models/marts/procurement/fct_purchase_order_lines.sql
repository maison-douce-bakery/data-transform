with po_lines as (

    select
        purchase_order_item_id,
        purchase_order_id,
        stock_item_id,
        ordered_quantity,
        uom_id,
        expected_unit_cost,
        notes,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__purchase_order_items') }} where not is_deleted

),

purchase_orders as (

    select
        purchase_order_id,
        po_number,
        supplier_id,
        branch_id,
        ordered_at,
        expected_at,
        status,
        currency_code,
        notes,
        created_by,
        created_at,
        updated_at,
        is_deleted,
        deleted_at
    from {{ ref('stg_bakery__purchase_orders') }} where not is_deleted

),

receipts as (

    select
        purchase_order_item_id,
        receipt_line_count,
        received_quantity_in_ordered_uom,
        other_uom_receipt_line_count,
        received_value,
        unpriced_receipt_line_count,
        first_received_at,
        last_received_at
    from {{ ref('int_procurement__receipt_totals_by_po_line') }}

),

joined as (

    select
        l.purchase_order_item_id,
        l.purchase_order_id,
        po.po_number,
        po.status as po_status,
        po.currency_code,
        po.supplier_id,
        po.branch_id,
        l.stock_item_id,
        l.uom_id,
        po.ordered_at,
        {{ business_date('po.ordered_at') }} as business_date,
        po.expected_at,
        {{ business_date('po.expected_at') }} as expected_date,
        l.ordered_quantity,
        l.expected_unit_cost,
        -- NULL (not 0) when the price is unknown.
        l.ordered_quantity * l.expected_unit_cost as expected_line_value,
        coalesce(r.receipt_line_count, 0) as receipt_line_count,
        coalesce(r.received_quantity_in_ordered_uom, 0) as received_quantity,
        coalesce(r.other_uom_receipt_line_count, 0) as other_uom_receipt_line_count,
        r.received_value,
        r.first_received_at,
        r.last_received_at
    from po_lines as l
    inner join purchase_orders as po on l.purchase_order_id = po.purchase_order_id
    left join receipts as r on l.purchase_order_item_id = r.purchase_order_item_id

),

final as (

    select
        j.purchase_order_item_id,
        j.purchase_order_id,
        j.po_number,
        j.po_status,
        j.currency_code,
        s.supplier_sk,
        j.supplier_id,
        b.branch_sk,
        j.branch_id,
        i.stock_item_sk,
        j.stock_item_id,
        u.uom_sk,
        j.uom_id,
        {{ date_sk('j.business_date') }} as date_sk,
        j.ordered_at,
        j.business_date,
        j.expected_at,
        j.expected_date,
        {{ date_sk('j.expected_date') }} as expected_date_sk,
        j.ordered_quantity,
        j.expected_unit_cost,
        j.expected_line_value,
        j.expected_unit_cost is not null as is_expected_price_known,
        j.receipt_line_count,
        j.received_quantity as received_quantity_in_ordered_uom,
        j.other_uom_receipt_line_count,
        j.other_uom_receipt_line_count = 0 as units_comparable,
        j.received_value,
        -- Quantity still awaited in the ordered unit; NULL when not comparable or cancelled.
        case
            when j.po_status = 'CANCELLED' or j.other_uom_receipt_line_count > 0 then null
            else greatest(j.ordered_quantity - j.received_quantity, 0)
        end as open_quantity,
        case
            when j.other_uom_receipt_line_count > 0 then null
            else greatest(j.received_quantity - j.ordered_quantity, 0)
        end as over_received_quantity,
        j.po_status = 'CANCELLED' as is_cancelled,
        j.first_received_at,
        j.last_received_at
    from joined as j
    left join {{ ref('dim_suppliers') }} as s on j.supplier_id = s.supplier_id
    left join {{ ref('dim_branches') }} as b on j.branch_id = b.branch_id
    left join {{ ref('dim_stock_items') }} as i on j.stock_item_id = i.stock_item_id
    left join {{ ref('dim_units_of_measure') }} as u on j.uom_id = u.uom_id

)

select
    purchase_order_item_id,
    purchase_order_id,
    po_number,
    po_status,
    currency_code,
    supplier_sk,
    supplier_id,
    branch_sk,
    branch_id,
    stock_item_sk,
    stock_item_id,
    uom_sk,
    uom_id,
    date_sk,
    ordered_at,
    business_date,
    expected_at,
    expected_date,
    expected_date_sk,
    ordered_quantity,
    expected_unit_cost,
    expected_line_value,
    is_expected_price_known,
    receipt_line_count,
    received_quantity_in_ordered_uom,
    other_uom_receipt_line_count,
    units_comparable,
    received_value,
    open_quantity,
    over_received_quantity,
    is_cancelled,
    first_received_at,
    last_received_at
from final
