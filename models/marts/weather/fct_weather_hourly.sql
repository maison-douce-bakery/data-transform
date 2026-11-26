-- One row per location and hour. weather_category groups the WMO weather_code.
select
    location_code,
    observed_at,
    {{ date_sk('business_date') }} as date_sk,
    business_date,
    business_hour,
    temperature_c,
    apparent_temperature_c,
    relative_humidity_pct,
    precipitation_mm,
    rain_mm,
    weather_code,
    case
        when weather_code in (0, 1) then 'clear'
        when weather_code in (2, 3) then 'cloudy'
        when weather_code in (45, 48) then 'fog'
        when weather_code between 51 and 57 then 'drizzle'
        when weather_code between 61 and 67 or weather_code between 80 and 82 then 'rain'
        when weather_code between 71 and 77 or weather_code in (85, 86) then 'snow'
        when weather_code in (95, 96, 99) then 'thunderstorm'
        else 'unknown'
    end as weather_category,
    coalesce(precipitation_mm > 0, false) as is_raining,
    cloud_cover_pct,
    shortwave_radiation_wm2,
    wind_speed_kmh
from {{ ref('stg_open_meteo__hourly_weather') }}
