-- Drawer cash in and out per shift. The opening float is not here: it lives on the shift (opening_cash)
-- and is added once in fct_shifts. FLOAT_IN movements are top-ups during the shift.
select
    shift_id,
    count(*) as movement_count,
    coalesce(sum(amount) filter (where movement_type = 'FLOAT_IN'), 0) as float_in_amount,
    coalesce(sum(amount) filter (where movement_type = 'SALE_CASH_IN'), 0) as sale_cash_in_amount,
    coalesce(sum(amount) filter (where movement_type = 'OTHER_IN'), 0) as other_in_amount,
    coalesce(sum(amount) filter (where movement_type = 'CASH_OUT'), 0) as cash_out_amount,
    coalesce(sum(amount) filter (where movement_type = 'REFUND_OUT'), 0) as refund_out_amount,
    coalesce(sum(amount) filter (where movement_type = 'OTHER_OUT'), 0) as other_out_amount,
    coalesce(sum(amount) filter (where direction = 'IN'), 0) as total_cash_in_amount,
    coalesce(sum(amount) filter (where direction = 'OUT'), 0) as total_cash_out_amount
from {{ ref('int_finance__cash_movements') }}
group by shift_id
