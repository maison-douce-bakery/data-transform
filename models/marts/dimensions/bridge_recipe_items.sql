-- Recipe component bridge, one row per recipe x stock item (non-deleted rows only). It is a relationship,
-- not a key target, so deleted rows are dropped. Quantities are per standard batch, in the component's own
-- unit; scale to a requested output with quantity_per_output_unit x requested output (same output unit).
select
    {{ dbt_utils.generate_surrogate_key(['i.recipe_item_id']) }} as recipe_item_sk,
    i.recipe_item_id,
    r.recipe_sk,
    r.recipe_id,
    r.product_id,
    {{ dbt_utils.generate_surrogate_key(['i.stock_item_id']) }} as stock_item_sk,
    i.stock_item_id,
    i.quantity as quantity_per_standard_batch,
    {{ dbt_utils.generate_surrogate_key(['i.uom_id']) }} as uom_sk,
    i.uom_id,
    r.standard_output_quantity,
    r.standard_output_uom_id,
    i.quantity / r.standard_output_quantity as quantity_per_output_unit,
    i.is_optional
from {{ ref('stg_bakery__recipe_items') }} as i
inner join {{ ref('dim_recipes') }} as r on i.recipe_id = r.recipe_id
where not i.is_deleted and not r.is_deleted
