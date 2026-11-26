{# Surrogate key of one dimension version: business key plus version start (epoch, so it does not depend on the session time zone). #}
{% macro scd2_surrogate_key(key_column, valid_from_column) -%}
    {{ dbt_utils.generate_surrogate_key([key_column, 'extract(epoch from ' ~ valid_from_column ~ ')']) }}
{%- endmacro %}

{# First version of each key starts at -infinity so events older than the first snapshot still resolve. #}
{% macro scd2_valid_from(key_column) -%}
    case
        when row_number() over (partition by {{ key_column }} order by valid_from) = 1
            then '-infinity'::timestamptz
        else valid_from
    end
{%- endmacro %}

{# End of validity of the current version. Keep equal to dbt_valid_to_current in dbt_project.yml. #}
{% macro scd_end_of_time() -%}
    '9999-12-31 00:00:00+00'::timestamptz
{%- endmacro %}
