with source as (

    select * from {{ source('bakery', 'simulation_runs') }}

),

renamed as (

    select
        simulation_run_id,
        run_key,
        business_date,
        random_seed,
        status,
        started_at,
        finished_at,
        records_created,
        error_message,
        notes
    from source

)

select * from renamed
