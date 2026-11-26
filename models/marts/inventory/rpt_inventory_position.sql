-- Stock position as of the build time, one row per branch x stock item x lot (lot may be NULL for lot-less stock).
-- as_of_date is the business date of now(); all movements up to that date count, none after.
-- Book on-hand = sum of signed movements. Available on-hand excludes expired lots: a lot is usable on its
-- expiry date and expired from the next day; lots without an expiry date never expire.
-- Lots whose net balance is 0 (fully consumed) are left out with HAVING; lots with no movements never
-- appear (a lot record alone does not mean stock exists). Negative balances are kept and flagged.
-- Quantities are never added across units: if one key had movements in several units, they are NULL and
-- has_mixed_uom is true.
-- Value uses the lot unit cost; with an unknown cost the value is NULL (never 0) and has_unknown_cost is true.
with as_of as (

    select {{ business_date('now()') }} as as_of_date

),

net_by_uom as (

    select
        m.branch_id,
        m.stock_item_id,
        m.inventory_lot_id,
        m.uom_id,
        sum(m.signed_quantity) as net_quantity
    from {{ ref('int_inventory__movements_signed') }} as m
    cross join as_of as a
    where m.business_date <= a.as_of_date
    group by m.branch_id, m.stock_item_id, m.inventory_lot_id, m.uom_id

),

positions as (

    select
        branch_id,
        stock_item_id,
        inventory_lot_id,
        count(*) as uom_count,
        min(uom_id) as uom_id,
        sum(net_quantity) as net_quantity
    from net_by_uom
    group by branch_id, stock_item_id, inventory_lot_id
    having bool_or(net_quantity <> 0)

),

enriched as (

    select
        a.as_of_date,
        p.branch_id,
        p.stock_item_id,
        p.inventory_lot_id,
        p.uom_count > 1 as has_mixed_uom,
        case when p.uom_count = 1 then p.uom_id end as uom_id,
        case when p.uom_count = 1 then p.net_quantity end as book_quantity,
        l.expiry_date,
        l.unit_cost,
        coalesce(a.as_of_date > l.expiry_date, false) as is_expired
    from positions as p
    cross join as_of as a
    left join {{ ref('dim_inventory_lots') }} as l on p.inventory_lot_id = l.inventory_lot_id

)

select
    e.as_of_date,
    br.branch_sk,
    e.branch_id,
    br.branch_code,
    si.stock_item_sk,
    e.stock_item_id,
    si.stock_item_code,
    si.stock_item_name,
    si.item_type,
    lot.inventory_lot_sk,
    e.inventory_lot_id,
    lot.lot_code,
    u.uom_sk,
    e.uom_id,
    u.uom_code,
    lot.received_date,
    lot.manufactured_date,
    e.expiry_date,
    e.expiry_date - e.as_of_date as days_to_expiry,
    e.is_expired,
    e.book_quantity,
    case
        when e.book_quantity is null then null
        when e.is_expired then 0
        else e.book_quantity
    end as available_quantity,
    case
        when e.book_quantity is null then null
        when e.is_expired then greatest(e.book_quantity, 0)
        else 0
    end as expired_quantity,
    e.unit_cost,
    e.book_quantity * e.unit_cost as book_value,
    case
        when e.book_quantity is null then null
        when e.is_expired then 0
        else e.book_quantity * e.unit_cost
    end as available_value,
    case
        when e.book_quantity is null then null
        when e.is_expired then greatest(e.book_quantity, 0) * e.unit_cost
        else 0
    end as expired_value,
    e.unit_cost is null as has_unknown_cost,
    e.book_quantity < 0 as is_negative_balance,
    e.has_mixed_uom
from enriched as e
left join {{ ref('dim_branches') }} as br on e.branch_id = br.branch_id
left join {{ ref('dim_stock_items') }} as si on e.stock_item_id = si.stock_item_id
left join {{ ref('dim_inventory_lots') }} as lot on e.inventory_lot_id = lot.inventory_lot_id
left join {{ ref('dim_units_of_measure') }} as u on e.uom_id = u.uom_id
