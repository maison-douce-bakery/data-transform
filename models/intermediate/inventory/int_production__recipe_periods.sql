-- Resolved recipe validity: one row per product and contiguous period in which exactly one recipe
-- version applies. Periods are half-open [period_start, period_end); period_end 9999-12-31 is open-ended.
-- Overlaps are resolved by the latest effective start (BL 7.1); ties go to the latest created version.
-- Dates with no valid version are simply not covered. Versions are never merged into one recipe.
with versions as (

    select
        recipe_id,
        product_id,
        effective_from as version_start,
        case
            when effective_to is null then date '9999-12-31'
            else effective_to + 1
        end as version_end,
        created_at
    from {{ ref('stg_bakery__recipes') }}
    where not is_deleted

),

boundaries as (

    select product_id, version_start as boundary_date from versions
    union
    select product_id, version_end from versions

),

segments as (

    select
        product_id,
        boundary_date as segment_start,
        lead(boundary_date) over (partition by product_id order by boundary_date) as segment_end
    from boundaries

),

winners as (

    select
        s.product_id,
        s.segment_start,
        s.segment_end,
        v.recipe_id,
        row_number() over (
            partition by s.product_id, s.segment_start
            order by v.version_start desc, v.created_at desc, v.recipe_id desc
        ) as winner_rank
    from segments as s
    inner join versions as v
        on s.product_id = v.product_id
        and v.version_start <= s.segment_start
        and v.version_end > s.segment_start
    where s.segment_end is not null

),

chosen as (

    select product_id, segment_start, segment_end, recipe_id
    from winners
    where winner_rank = 1

),

flagged as (

    select
        product_id,
        segment_start,
        segment_end,
        recipe_id,
        case
            when lag(recipe_id) over w is not distinct from recipe_id
                and lag(segment_end) over w = segment_start
                then 0
            else 1
        end as starts_new_period
    from chosen
    window w as (partition by product_id order by segment_start)

),

islands as (

    select
        product_id,
        segment_start,
        segment_end,
        recipe_id,
        starts_new_period,
        sum(starts_new_period) over (partition by product_id order by segment_start) as period_number
    from flagged

)

select
    product_id,
    recipe_id,
    min(segment_start) as period_start,
    max(segment_end) as period_end
from islands
group by product_id, recipe_id, period_number
