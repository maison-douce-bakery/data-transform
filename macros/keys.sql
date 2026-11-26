{# Date surrogate key (YYYYMMDD integer) of a date expression; joins to dim_date.date_sk. #}
{% macro date_sk(date_expr) -%}
    to_char({{ date_expr }}, 'YYYYMMDD')::int
{%- endmacro %}
