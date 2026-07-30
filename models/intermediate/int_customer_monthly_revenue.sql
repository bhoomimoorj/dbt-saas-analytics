with invoices as (
    select * from {{ ref('stg_billing_invoices')}}
),
customer_month as (
    select
        customer_id,
        invoice_month,
        greatest(sum(actual_amount_eur), 0) as mrr 
    from invoices
    group by customer_id, invoice_month
),

cohort as (
    select customer_id, min(invoice_month) as cohort_month
    from customer_month
    group by customer_id
)

select 
    cm.customer_id,
    cm.invoice_month, 
    c.cohort_month,
    date_diff('month', c.cohort_month, cm.invoice_month) as months_since_start, 
    cm.mrr
from customer_month cm 
join cohort c using (customer_id)