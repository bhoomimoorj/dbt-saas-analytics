select cohort_month, nrr
from {{ref('nrr_by_cohort_month')}}
where months_since_start = 0
and nrr <> 1.0