-- Cash movements of live shifts with the direction taken from the movement type (amounts are always positive in the source).
-- Shared by fct_cash_movements and int_finance__shift_cash so the direction rule lives in one place.
with movements as (

    select * from {{ ref('stg_bakery__cash_movements') }} where not is_deleted

),

shifts as (

    select shift_id, branch_id from {{ ref('stg_bakery__shifts') }} where not is_deleted

)

select
    m.cash_movement_id,
    m.shift_id,
    s.branch_id,
    m.movement_type,
    case
        when m.movement_type in ('FLOAT_IN', 'SALE_CASH_IN', 'OTHER_IN') then 'IN'
        when m.movement_type in ('CASH_OUT', 'REFUND_OUT', 'OTHER_OUT') then 'OUT'
    end as direction,
    m.amount,
    case
        when m.movement_type in ('FLOAT_IN', 'SALE_CASH_IN', 'OTHER_IN') then m.amount
        when m.movement_type in ('CASH_OUT', 'REFUND_OUT', 'OTHER_OUT') then -m.amount
    end as signed_amount,
    m.occurred_at,
    m.sale_id,
    m.recorded_by,
    m.description
from movements as m
inner join shifts as s on m.shift_id = s.shift_id
