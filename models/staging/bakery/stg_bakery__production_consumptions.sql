select
    production_consumption_id,
    production_batch_id,
    stock_item_id,
    inventory_lot_id,
    quantity_used,
    uom_id,
    unit_cost,
    notes,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'production_consumptions') }}
