-- SCD2 dimension over snap_products. Category and unit of measure come from the
-- current state of their staging tables; category history is not tracked.
with versions as (

    select
        *,
        {{ scd2_valid_from('product_id') }} as version_valid_from
    from {{ ref('snap_products') }}

),

categories as (

    select
        c.category_id,
        c.category_code,
        c.category_name,
        p.category_name as parent_category_name
    from {{ ref('stg_bakery__product_categories') }} as c
    left join {{ ref('stg_bakery__product_categories') }} as p
        on c.parent_category_id = p.category_id

),

units as (

    select uom_id, uom_code, uom_name
    from {{ ref('stg_bakery__units_of_measure') }}

)

select
    {{ scd2_surrogate_key('v.product_id', 'v.version_valid_from') }} as product_sk,
    v.product_id,
    v.sku,
    v.product_name,
    v.product_type,
    v.category_id,
    c.category_code,
    c.category_name,
    c.parent_category_name,
    v.sell_uom_id,
    u.uom_code as sell_uom_code,
    u.uom_name as sell_uom_name,
    v.stock_item_id,
    v.description,
    v.ingredient_summary,
    v.unit_price,
    v.is_active,
    v.available_from,
    v.available_to,
    v.version_valid_from as valid_from,
    v.valid_to,
    v.valid_to = {{ scd_end_of_time() }} as is_current,
    v.is_deleted
from versions as v
left join categories as c on v.category_id = c.category_id
left join units as u on v.sell_uom_id = u.uom_id
