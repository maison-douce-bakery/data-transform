with shifts as (

    select * from {{ ref('stg_bakery__shifts') }} where not is_deleted

),

cash as (

    select * from {{ ref('int_finance__shift_cash') }}

),

joined as (

    select
        s.shift_id,
        s.shift_code,
        s.branch_id,
        s.employee_id,
        s.status,
        s.opened_at,
        s.closed_at,
        s.opening_cash as opening_float_amount,
        coalesce(c.movement_count, 0) as cash_movement_count,
        coalesce(c.float_in_amount, 0) as float_in_amount,
        coalesce(c.sale_cash_in_amount, 0) as sale_cash_in_amount,
        coalesce(c.other_in_amount, 0) as other_in_amount,
        coalesce(c.cash_out_amount, 0) as cash_out_amount,
        coalesce(c.refund_out_amount, 0) as refund_out_amount,
        coalesce(c.other_out_amount, 0) as other_out_amount,
        coalesce(c.total_cash_in_amount, 0) as total_cash_in_amount,
        coalesce(c.total_cash_out_amount, 0) as total_cash_out_amount,
        s.counted_cash as counted_closing_cash_amount
    from shifts as s
    left join cash as c on s.shift_id = c.shift_id

),

final as (

    select
        j.shift_id,
        j.shift_code,
        b.branch_sk,
        j.branch_id,
        e.employee_sk,
        j.employee_id,
        j.status,
        j.opened_at,
        {{ date_sk(business_date('j.opened_at')) }} as date_sk,
        {{ business_date('j.opened_at') }} as business_date,
        j.closed_at,
        {{ date_sk(business_date('j.closed_at')) }} as closed_date_sk,
        {{ business_date('j.closed_at') }} as closed_date,
        j.opening_float_amount,
        j.cash_movement_count,
        j.float_in_amount,
        j.sale_cash_in_amount,
        j.other_in_amount,
        j.cash_out_amount,
        j.refund_out_amount,
        j.other_out_amount,
        j.total_cash_in_amount,
        j.total_cash_out_amount,
        -- The opening float is added once; a FLOAT_IN movement is a separate top-up. For an OPEN shift this is the running figure.
        j.opening_float_amount + j.total_cash_in_amount - j.total_cash_out_amount as expected_closing_cash_amount,
        j.counted_closing_cash_amount,
        -- Counted minus expected (positive = over, negative = short); NULL until a count exists.
        j.counted_closing_cash_amount
            - (j.opening_float_amount + j.total_cash_in_amount - j.total_cash_out_amount) as cash_variance_amount,
        j.status = 'CLOSED' as is_closed,
        j.counted_closing_cash_amount is not null as has_counted_cash,
        j.counted_closing_cash_amount
            = (j.opening_float_amount + j.total_cash_in_amount - j.total_cash_out_amount) as is_counted_equal_expected,
        -- Possible double count of the opening float: a top-up equal to the opening float.
        j.float_in_amount > 0 and j.float_in_amount = j.opening_float_amount as is_float_in_equal_opening_float
    from joined as j
    left join {{ ref('dim_branches') }} as b on j.branch_id = b.branch_id
    left join {{ ref('dim_employees') }} as e
        on j.employee_id = e.employee_id
        and j.opened_at >= e.valid_from
        and j.opened_at < e.valid_to

)

select * from final
