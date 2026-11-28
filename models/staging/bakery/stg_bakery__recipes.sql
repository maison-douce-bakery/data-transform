select
    recipe_id,
    product_id,
    recipe_version,
    yield_quantity,
    yield_uom_id,
    effective_from,
    effective_to,
    instructions,
    is_active,
    _created_at as created_at,
    _last_updated_at as updated_at,
    _is_deleted as is_deleted,
    _deleted_at as deleted_at
from {{ source('bakery', 'recipes') }}
