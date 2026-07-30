select customer_id, invoice_month
from {{ref('int_customer_monthly_revenue')}}
group by customer_id, invoice_month 
having count(*) > 1