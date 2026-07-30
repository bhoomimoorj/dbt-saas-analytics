with source as (
    select * from {{ref('int_customer_monthly_revenue')}}
),

cohort_base as (
    select cohort_month, sum(mrr) as base_mrr
    from source
    where months_since_start = 0
    group by cohort_month
),

cohort_period as (
    select cohort_month, months_since_start, sum(mrr) as cohort_mrr
    from source
    group by cohort_month, months_since_start
)

select
    p.cohort_month,
    p.months_since_start,
    b.base_mrr,
    p.cohort_mrr,
    round(p.cohort_mrr/nullif(b.base_mrr,0),4) as nrr
from cohort_period p
join cohort_base b using (cohort_month)
order by p.cohort_month, p.months_since_start
