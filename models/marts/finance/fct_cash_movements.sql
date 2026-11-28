with movements as (

    select
        cash_movement_id,
        shift_id,
        branch_id,
        movement_type,
        direction,
        amount,
        signed_amount,
        occurred_at,
        sale_id,
        recorded_by,
        description
    from {{ ref('int_finance__cash_movements') }}

)

select
    m.cash_movement_id,
    m.shift_id,
    b.branch_sk,
    m.branch_id,
    e.employee_sk as recorded_by_employee_sk,
    m.recorded_by as recorded_by_employee_id,
    m.movement_type,
    m.direction,
    m.amount,
    m.signed_amount,
    m.occurred_at,
    {{ date_sk(business_date('m.occurred_at')) }} as date_sk,
    {{ business_date('m.occurred_at') }} as business_date,
    -- Source sale of a sale cash receipt or a cash refund. The source stores no return id.
    m.sale_id,
    m.sale_id is not null as has_sale_link,
    m.movement_type = 'REFUND_OUT' as is_refund,
    m.description
from movements as m
left join {{ ref('dim_branches') }} as b on m.branch_id = b.branch_id
left join {{ ref('dim_employees') }} as e
    on m.recorded_by = e.employee_id
    and m.occurred_at >= e.valid_from
    and m.occurred_at < e.valid_to
