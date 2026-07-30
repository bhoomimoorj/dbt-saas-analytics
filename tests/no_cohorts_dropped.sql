-- Every cohort in the revenue spine must reach the mart. The mart's inner join
-- to the month-0 base could silently drop a cohort -- this catches that.
-- Returns cohorts present upstream but missing in the mart -> should be none.
select cohort_month from {{ ref('int_customer_monthly_revenue') }}
except
select cohort_month from {{ ref('nrr_by_cohort_month') }}
