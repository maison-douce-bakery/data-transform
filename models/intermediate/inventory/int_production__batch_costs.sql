-- Material input cost of each non-deleted production batch: sum(consumed quantity x lot unit cost).
-- Consumption rows mirror the negative PRODUCTION_CONSUMPTION movements (same event), so only
-- production_consumptions is used here and the movements are never added on top.
-- Materials only: no labour or overhead, so this is not profit. Unknown costs are never turned into 0.
with batches as (

    select
        production_batch_id,
        produced_quantity
    from {{ ref('stg_bakery__production_batches') }}
    where not is_deleted

),

lines as (

    select
        c.production_batch_id,
        c.quantity_used * coalesce(l.unit_cost, c.unit_cost) as line_cost,
        coalesce(l.unit_cost, c.unit_cost) is null as is_cost_unknown
    from {{ ref('stg_bakery__production_consumptions') }} as c
    left join {{ ref('stg_bakery__inventory_lots') }} as l on c.inventory_lot_id = l.inventory_lot_id
    where not c.is_deleted

),

batch_lines as (

    select
        production_batch_id,
        count(*) as consumption_line_count,
        count(*) filter (where is_cost_unknown) as unknown_cost_line_count,
        sum(line_cost) as known_material_cost
    from lines
    group by production_batch_id

),

joined as (

    select
        b.production_batch_id,
        b.produced_quantity,
        coalesce(bl.consumption_line_count, 0) as consumption_line_count,
        coalesce(bl.unknown_cost_line_count, 0) as unknown_cost_line_count,
        bl.known_material_cost
    from batches as b
    left join batch_lines as bl on b.production_batch_id = bl.production_batch_id

)

select
    production_batch_id,
    consumption_line_count,
    unknown_cost_line_count,
    -- A batch without consumption rows has no known input cost, not a zero one.
    (consumption_line_count = 0 or unknown_cost_line_count > 0) as has_unknown_cost,
    -- Sum of the lines that have a cost; only the full cost when has_unknown_cost is false.
    known_material_cost,
    case
        when consumption_line_count > 0 and unknown_cost_line_count = 0 then known_material_cost
    end as material_cost,
    case
        when consumption_line_count > 0 and unknown_cost_line_count = 0 and produced_quantity > 0
            then known_material_cost / produced_quantity
    end as unit_cost
from joined
