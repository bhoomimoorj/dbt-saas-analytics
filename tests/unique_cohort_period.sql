select cohort_month, months_since_start
from {{ref('nrr_by_cohort_month')}}
group by cohort_month, months_since_start
having count(*) > 1 