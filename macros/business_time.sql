{# Local business calendar date of a timestamptz column. #}
{% macro business_date(ts_column) -%}
    (({{ ts_column }} at time zone '{{ var("business_timezone") }}')::date)
{%- endmacro %}

{# Local business wall-clock time (timestamp without time zone) of a timestamptz column. #}
{% macro business_timestamp(ts_column) -%}
    ({{ ts_column }} at time zone '{{ var("business_timezone") }}')
{%- endmacro %}
