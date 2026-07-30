with source as (
    select * from {{ ref('crm_subscriptions')}}
),

cleaned as (
    select
        subscription_id, 
        customer_id, 
        plan, 
        cast(signed_mrr_eur as integer) as signed_mrr_eur,
        cast(start_date as date) as start_date, 
        cast(end_date as date) as end_date, 
        coalesce(
            nullif(lower(trim(status)), ''),
            case when end_date is null then 'active' else 'churned' end
        ) as status
    from source 
), 

deduped as (
    select *,
        row_number() over (
        partition by subscription_id
        order by subscription_id
        ) as rn
    from cleaned 
)

select 
    subscription_id, 
    customer_id, 
    plan, 
    signed_mrr_eur, 
    start_date, 
    end_date, 
    status
from deduped
where rn = 1