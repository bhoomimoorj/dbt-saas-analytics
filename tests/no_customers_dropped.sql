-- Every customer that has invoices must survive the join into the revenue model.
-- Returns customers present in billing but missing downstream -> should be none.
select customer_id from {{ ref('stg_billing_invoices') }}
except
select customer_id from {{ ref('int_customer_monthly_revenue') }}
