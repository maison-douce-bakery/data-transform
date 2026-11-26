with source as (

    select * from {{ source('bakery', 'sale_promotions') }}

),

renamed as (

    select
        sale_promotion_id,
        sale_id,
        promotion_id,
        discount_amount,
        coupon_code,
        applied_at,
        _created_at as created_at,
        _last_updated_at as updated_at,
        _is_deleted as is_deleted,
        _deleted_at as deleted_at
    from source

)

select * from renamed
