with spine as (

    {{ dbt_utils.date_spine(
        datepart='day',
        start_date="cast('" ~ var('calendar_start_date') ~ "' as date)",
        end_date="cast('" ~ var('calendar_end_date') ~ "' as date) + 1"
    ) }}

),

days as (

    select cast(date_day as date) as date_day from spine

)

select
    d.date_day,
    {{ date_sk('d.date_day') }} as date_sk,
    extract(year from d.date_day)::int as year,
    extract(quarter from d.date_day)::int as quarter,
    extract(month from d.date_day)::int as month,
    trim(to_char(d.date_day, 'Month')) as month_name,
    extract(isoyear from d.date_day)::int as iso_year,
    extract(week from d.date_day)::int as iso_week,
    extract(isodow from d.date_day)::int as day_of_week,
    trim(to_char(d.date_day, 'Day')) as day_name,
    extract(isodow from d.date_day) in (6, 7) as is_weekend,
    h.holiday_date is not null as is_holiday,
    h.holiday_name,
    case
        when h.holiday_date is not null then 'HOLIDAY'
        when extract(isodow from d.date_day) in (6, 7) then 'WEEKEND'
        else 'WEEKDAY'
    end as date_type
from days as d
left join {{ ref('vietnam_holidays') }} as h on d.date_day = h.holiday_date
