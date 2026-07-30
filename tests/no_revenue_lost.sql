-- Revenue reconciliation. The modeled total can be HIGHER than raw invoiced
-- (the floor lifts negative refund-months up to 0), but it must never be LOWER
-- -- a shortfall would mean rows/amounts were dropped by a join or filter.
-- Returns a row only if revenue went missing -> should be none.
with invoiced as (
    select sum(actual_amount_eur) as total from {{ ref('stg_billing_invoices') }}
),
modeled as (
    select sum(mrr) as total from {{ ref('int_customer_monthly_revenue') }}
)
select invoiced.total as invoiced_total, modeled.total as modeled_total
from invoiced, modeled
where modeled.total < invoiced.total
