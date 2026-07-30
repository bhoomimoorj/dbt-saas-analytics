with source as (
    select * from {{ref('billing_invoices')}}
),

cleaned as (
    select
        invoice_id, 
        customer_id, 
        subscription_id, 
        cast(invoice_month as date) as invoice_month, 
        cast(actual_amount_eur as decimal(10,2)) as actual_amount_eur
    from source 
),

deduped as (
    select *, 
    row_number() over (
        partition by invoice_id
        order by invoice_id
        ) as rn
    from cleaned
)

select
    invoice_id, 
    customer_id,
    subscription_id, 
    invoice_month, 
    actual_amount_eur
from deduped
where rn=1