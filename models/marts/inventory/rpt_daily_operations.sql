-- Daily operations, one row per business_date x branch x unit of measure (days and units with no activity have no row).
-- Quantities are only added within one unit of measure. Units of different dimensions never share a row.
-- Production quantities are in the batch (product) unit; waste and stock movements are in the stock item unit.
-- Production is dated by the batch start (see fct_production_batches.business_date).
-- Stock movement totals add all items of that unit, so they are unit totals, not item counts.
-- waste_share_of_production compares only waste of produced items (items that are the output of a batch)
-- with production output of the same unit; waste of raw materials or bought goods is not comparable.
with production as (

    select
        business_date,
        branch_id,
        uom_id,
        count(*) as batch_count,
        count(*) filter (where status = 'COMPLETED') as completed_batch_count,
        count(*) filter (where status = 'CANCELLED') as cancelled_batch_count,
        sum(planned_quantity) filter (where status <> 'CANCELLED') as planned_quantity,
        sum(output_quantity) as output_quantity,
        -- Attainment compares actual with planned over the same batches only.
        sum(planned_quantity) filter (where is_attainment_comparable) as attainment_planned_quantity,
        sum(output_quantity) filter (where is_attainment_comparable) as attainment_output_quantity,
        sum(material_cost) filter (where status = 'COMPLETED') as known_complete_material_cost,
        count(*) filter (where status = 'COMPLETED' and has_unknown_cost) as unknown_cost_batch_count
    from {{ ref('fct_production_batches') }}
    group by business_date, branch_id, uom_id

),

produced_items as (

    select distinct p.stock_item_id
    from {{ ref('fct_production_batches') }} as b
    inner join {{ ref('dim_products') }} as p on b.product_id = p.product_id
    where p.stock_item_id is not null

),

waste as (

    select
        w.business_date,
        w.branch_id,
        w.uom_id,
        count(*) as waste_record_count,
        sum(w.quantity) as waste_quantity,
        sum(w.quantity) filter (where pi.stock_item_id is not null) as produced_item_waste_quantity,
        sum(w.waste_value) as known_waste_value,
        count(*) filter (where w.has_unknown_cost) as unknown_cost_waste_record_count
    from {{ ref('fct_waste_records') }} as w
    left join produced_items as pi on w.stock_item_id = pi.stock_item_id
    group by w.business_date, w.branch_id, w.uom_id

),

movements as (

    select
        business_date,
        branch_id,
        uom_id,
        count(*) as stock_movement_count,
        sum(signed_quantity) filter (where movement_type = 'PURCHASE_RECEIPT') as purchase_receipt_quantity,
        sum(signed_quantity) filter (where movement_type = 'PRODUCTION_OUTPUT') as production_output_movement_quantity,
        sum(signed_quantity) filter (where movement_type = 'RETURN_IN') as return_in_quantity,
        sum(signed_quantity) filter (where movement_type = 'SALE') as sale_quantity,
        sum(signed_quantity) filter (where movement_type = 'PRODUCTION_CONSUMPTION') as production_consumption_quantity,
        sum(signed_quantity) filter (where movement_type = 'WASTE') as waste_movement_quantity,
        sum(signed_quantity) filter (where movement_type in ('TRANSFER_IN', 'TRANSFER_OUT')) as net_transfer_quantity,
        sum(signed_quantity) filter (where movement_type in ('ADJUSTMENT_IN', 'ADJUSTMENT_OUT')) as net_adjustment_quantity,
        sum(signed_quantity) as net_movement_quantity
    from {{ ref('fct_stock_movements') }}
    group by business_date, branch_id, uom_id

),

keys as (

    select business_date, branch_id, uom_id from production
    union
    select business_date, branch_id, uom_id from waste
    union
    select business_date, branch_id, uom_id from movements

)

select
    {{ date_sk('k.business_date') }} as date_sk,
    k.business_date,
    br.branch_sk,
    k.branch_id,
    u.uom_sk,
    k.uom_id,
    u.uom_code,
    u.dimension as uom_dimension,
    coalesce(p.batch_count, 0) as batch_count,
    coalesce(p.completed_batch_count, 0) as completed_batch_count,
    coalesce(p.cancelled_batch_count, 0) as cancelled_batch_count,
    p.planned_quantity,
    p.output_quantity,
    p.attainment_planned_quantity,
    p.attainment_output_quantity,
    p.attainment_output_quantity / nullif(p.attainment_planned_quantity, 0) as attainment_ratio,
    p.known_complete_material_cost,
    coalesce(p.unknown_cost_batch_count, 0) as unknown_cost_batch_count,
    coalesce(w.waste_record_count, 0) as waste_record_count,
    w.waste_quantity,
    w.produced_item_waste_quantity,
    w.known_waste_value,
    coalesce(w.unknown_cost_waste_record_count, 0) as unknown_cost_waste_record_count,
    w.produced_item_waste_quantity / nullif(p.output_quantity, 0) as waste_share_of_production,
    coalesce(m.stock_movement_count, 0) as stock_movement_count,
    m.purchase_receipt_quantity,
    m.production_output_movement_quantity,
    m.return_in_quantity,
    m.sale_quantity,
    m.production_consumption_quantity,
    m.waste_movement_quantity,
    m.net_transfer_quantity,
    m.net_adjustment_quantity,
    m.net_movement_quantity
from keys as k
left join production as p
    on k.business_date = p.business_date and k.branch_id is not distinct from p.branch_id and k.uom_id = p.uom_id
left join waste as w
    on k.business_date = w.business_date and k.branch_id is not distinct from w.branch_id and k.uom_id = w.uom_id
left join movements as m
    on k.business_date = m.business_date and k.branch_id is not distinct from m.branch_id and k.uom_id = m.uom_id
left join {{ ref('dim_branches') }} as br on k.branch_id = br.branch_id
left join {{ ref('dim_units_of_measure') }} as u on k.uom_id = u.uom_id
