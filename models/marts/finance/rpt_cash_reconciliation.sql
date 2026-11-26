-- counted_cash_is_independent is evaluated per branch and business day (the day the shift opened):
-- false when no shift of that day has a count, or every counted shift equals its expected cash exactly.
-- Today the source sets counted cash = expected cash, so a zero variance is not evidence of a real count.
with shifts as (

    select * from {{ ref('fct_shifts') }}

),

branch_days as (

    select
        branch_id,
        business_date,
        count(*) as shift_count,
        coalesce(bool_or(has_counted_cash and not is_counted_equal_expected), false) as counted_cash_is_independent
    from shifts
    group by branch_id, business_date

)

select
    s.shift_id,
    s.shift_code,
    s.branch_sk,
    s.branch_id,
    b.branch_name,
    s.employee_sk,
    s.employee_id,
    e.full_name as employee_name,
    s.date_sk,
    s.business_date,
    s.status,
    s.opened_at,
    s.closed_at,
    s.opening_float_amount,
    s.float_in_amount,
    s.sale_cash_in_amount,
    s.other_in_amount,
    s.cash_out_amount,
    s.refund_out_amount,
    s.other_out_amount,
    s.total_cash_in_amount,
    s.total_cash_out_amount,
    s.expected_closing_cash_amount,
    s.counted_closing_cash_amount,
    s.cash_variance_amount,
    case
        when not s.has_counted_cash then 'NOT_COUNTED'
        when s.cash_variance_amount = 0 then 'BALANCED'
        when s.cash_variance_amount > 0 then 'OVER'
        else 'SHORT'
    end as variance_status,
    s.has_counted_cash,
    d.counted_cash_is_independent,
    d.shift_count as branch_day_shift_count,
    s.is_float_in_equal_opening_float
from shifts as s
inner join branch_days as d on s.branch_id = d.branch_id and s.business_date = d.business_date
left join {{ ref('dim_branches') }} as b on s.branch_sk = b.branch_sk
left join {{ ref('dim_employees') }} as e on s.employee_sk = e.employee_sk
