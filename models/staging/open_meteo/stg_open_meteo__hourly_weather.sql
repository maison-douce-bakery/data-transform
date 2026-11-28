-- Overlapping load windows append the same hour again: keep the latest revision per location and hour.
with source as (

    select
        location_code,
        latitude,
        longitude,
        observed_at_local,
        utc_offset_seconds,
        observed_at,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        rain,
        weather_code,
        cloud_cover,
        shortwave_radiation,
        wind_speed_10m,
        source,
        api_fetched_at,
        window_start,
        window_end,
        _dlt_load_id,
        _dlt_id
    from {{ source('open_meteo', 'open_meteo_hourly_weather') }}

),

latest as (

    select
        location_code,
        latitude,
        longitude,
        observed_at_local,
        utc_offset_seconds,
        observed_at,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        rain,
        weather_code,
        cloud_cover,
        shortwave_radiation,
        wind_speed_10m,
        source,
        api_fetched_at,
        window_start,
        window_end,
        _dlt_load_id,
        _dlt_id,
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

select
    location_code,
    observed_at,
    observed_local_at,
    business_date,
    business_hour,
    temperature_c,
    apparent_temperature_c,
    relative_humidity_pct,
    precipitation_mm,
    rain_mm,
    weather_code,
    cloud_cover_pct,
    shortwave_radiation_wm2,
    wind_speed_kmh,
    fetched_at
from renamed
