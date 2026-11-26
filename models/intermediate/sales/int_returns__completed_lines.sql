-- Return line grain: lines of COMPLETED returns, linked to the original sale line.
-- Header totals are never added to line amounts. Returns whose original line or sale is
-- soft-deleted drop out together with it.
with returns as (

    select * from {{ ref('stg_bakery__returns') }}
    where not is_deleted and status = 'COMPLETED'

),

return_items as (

    select * from {{ ref('stg_bakery__return_items') }}
    where not is_deleted

),

sale_lines as (

    select sale_item_id, sale_id, business_date as sale_date
    from {{ ref('int_sales__lines_enriched') }}

)

select
    ri.return_item_id,
    r.return_id,
    r.return_number,
    l.sale_id,
    ri.sale_item_id,
    r.processed_by,
    r.returned_at,
    {{ business_date('r.returned_at') }} as business_date,
    l.sale_date,
    r.reason,
    ri.quantity as returned_quantity,
    ri.refund_amount,
    ri.restockable,
    -- True when the return header points to the same sale as the original line
    r.sale_id = l.sale_id as is_sale_consistent
from return_items as ri
inner join returns as r on ri.return_id = r.return_id
inner join sale_lines as l on ri.sale_item_id = l.sale_item_id
