with source as (
    select * from {{ref('dim_customers')}}
),

cleaned as (
    select
    customer_id, 
    company_name, 
    case lower(trim(region))
        when 'germany' then 'DE'
        when 'de' then 'DE'
        when 'ch' then 'CH'
        when 'at' then 'AT'
        when 'dach' then 'DACH'
        else 'Unknown'
    end as region, 
    case lower(trim(segment))
        when 'smb' then 'SMB'
        when 'mid-market' then 'Mid-Market'
        when 'enterprise' then 'Enterprise'
        else 'Unknown'
    end as segment,
    cast (signup_date as date) as signup_date
from source
),

deduped as (
    select *,
    row_number() over (partition by customer_id
    order by case when region = 'DACH' then 1 else 0 end
    ) as rn 
from cleaned
)

select 
    customer_id, 
    company_name, 
    region, 
    segment, 
    signup_date
from deduped
where rn = 1