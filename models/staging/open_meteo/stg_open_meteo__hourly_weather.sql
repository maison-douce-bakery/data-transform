-- Overlapping load windows append the same hour again: keep the latest revision per location and hour.
with source as (

    select * from {{ source('open_meteo', 'open_meteo_hourly_weather') }}

),

latest as (

    select
        *,
        row_number() over (
            partition by location_code, observed_at
            order by api_fetched_at desc, _dlt_load_id desc
        ) as revision_rank
    from source

),

renamed as (

    select
        location_code,
        observed_at,
        {{ business_timestamp('observed_at') }} as observed_local_at,
        {{ business_date('observed_at') }} as business_date,
        extract(hour from {{ business_timestamp('observed_at') }})::int as business_hour,
        temperature_2m as temperature_c,
        apparent_temperature as apparent_temperature_c,
        relative_humidity_2m as relative_humidity_pct,
        precipitation as precipitation_mm,
        rain as rain_mm,
        weather_code,
        cloud_cover as cloud_cover_pct,
        shortwave_radiation as shortwave_radiation_wm2,
        wind_speed_10m as wind_speed_kmh,
        api_fetched_at as fetched_at
    from latest
    where revision_rank = 1

)

select * from renamed
