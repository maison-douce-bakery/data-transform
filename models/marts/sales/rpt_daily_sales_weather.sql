-- Same grain as rpt_daily_sales (branch and business date). Weather comes from the branch's location in
-- branch_locations (one row per branch) and rpt_daily_weather (one row per location and date), so no fan-out.
-- Days without a mapping or weather keep their sales and get null weather.
with sales as (

    select
        branch_sk,
        branch_id,
        branch_name,
        date_sk,
        business_date,
        order_count,
        customer_order_count,
        line_count,
        gross_amount,
        discount_amount,
        net_amount,
        tax_amount,
        revenue_amount,
        refund_amount_by_sale_date,
        net_revenue_amount_by_sale_date,
        return_line_count,
        refund_amount_by_refund_date,
        net_revenue_amount_by_refund_date,
        average_order_value
    from {{ ref('rpt_daily_sales') }}

),

branch_location as (

    select b.branch_id, l.location_code
    from {{ ref('dim_branches') }} as b
    inner join {{ ref('branch_locations') }} as l on b.branch_code = l.branch_code

)

select
    s.branch_sk,
    s.branch_id,
    s.branch_name,
    s.date_sk,
    s.business_date,
    s.order_count,
    s.revenue_amount,
    s.net_revenue_amount_by_sale_date,
    s.average_order_value,
    bl.location_code,
    w.hour_count as weather_hour_count,
    w.min_temperature_c,
    w.max_temperature_c,
    w.avg_temperature_c,
    w.total_precipitation_mm,
    w.rainy_hour_count,
    w.avg_relative_humidity_pct,
    w.max_wind_speed_kmh,
    w.dominant_weather_category
from sales as s
left join branch_location as bl on s.branch_id = bl.branch_id
left join {{ ref('rpt_daily_weather') }} as w
    on bl.location_code = w.location_code and s.business_date = w.business_date
