-- One row per location and business date, from the hours present in fct_weather_hourly (hour_count can be below 24).
with hourly as (

    select
        location_code,
        observed_at,
        date_sk,
        business_date,
        business_hour,
        temperature_c,
        apparent_temperature_c,
        relative_humidity_pct,
        precipitation_mm,
        rain_mm,
        weather_code,
        weather_category,
        is_raining,
        cloud_cover_pct,
        shortwave_radiation_wm2,
        wind_speed_kmh
    from {{ ref('fct_weather_hourly') }}

),

category_hours as (

    select
        location_code,
        business_date,
        weather_category,
        count(*) as category_hour_count
    from hourly
    group by location_code, business_date, weather_category

),

dominant_category as (

    select distinct on (location_code, business_date)
        location_code,
        business_date,
        weather_category
    from category_hours
    order by location_code, business_date, category_hour_count desc, weather_category

),

daily as (

    select
        location_code,
        business_date,
        count(*) as hour_count,
        min(temperature_c) as min_temperature_c,
        max(temperature_c) as max_temperature_c,
        avg(temperature_c) as avg_temperature_c,
        sum(precipitation_mm) as total_precipitation_mm,
        count(*) filter (where is_raining) as rainy_hour_count,
        avg(relative_humidity_pct) as avg_relative_humidity_pct,
        max(wind_speed_kmh) as max_wind_speed_kmh
    from hourly
    group by location_code, business_date

)

select
    d.location_code,
    {{ date_sk('d.business_date') }} as date_sk,
    d.business_date,
    d.hour_count,
    d.min_temperature_c,
    d.max_temperature_c,
    d.avg_temperature_c,
    d.total_precipitation_mm,
    d.rainy_hour_count,
    d.avg_relative_humidity_pct,
    d.max_wind_speed_kmh,
    c.weather_category as dominant_weather_category
from daily as d
left join dominant_category as c
    on d.location_code = c.location_code and d.business_date = c.business_date
