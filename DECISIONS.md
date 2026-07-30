# Decisions & Assumptions

## NRR definition & grain
NRR is measured at the grain of **cohort × months-since-start**. A cohort is the
set of customers sharing their **first invoiced month**; for each cohort I track
total recurring revenue at every subsequent month, indexed to the cohort's
month-0 revenue (`NRR = revenue at month N / revenue at month 0`). Revenue is
rolled up to the **customer** level (summed across all of a customer's
subscriptions). This captures expansion, contraction, and churn, and **excludes
net-new** customers automatically: every customer belongs to exactly one cohort
and is measured only against that cohort's own base, so later-joining customers
form their own cohorts rather than inflating an existing one.

## Signed vs. actual revenue
I use **actual invoiced amounts** as the revenue basis to reflect 
*realized* recurring revenue. Signed MRR (CRM) maps cleanly 1:1 to plan
(Starter 99 / Pro 299 / Scale 799) but is aspirational and would **overstate**
by ignoring everything that happens after signature.

## Handling ambiguous / messy records
- **Duplicates:** fully duplicated rows removed with a
  `row_number()` dedup on the natural key. Customers that appear twice with a
  *conflicting* region (`dach` vs `DE`), I kept the country-level value (`DE`)
  over the vaguer `DACH` grouping.
- **Status:** normalized casing (`Active` → `active`) and derived the one NULL
  status from `end_date` — no end date → active, else churned. 
- **Multiple contracts / plan change:** rolling revenue up to the customer means a
  mid-contract upgrade reads as **expansion**.
- **Churn:** implicit — a customer with no invoice in a month contributes 0 to
  that month. 
- **Negative invoices (refunds/credits):** netted against the same customer-month,
  then floored at 0 so a refund can't create negative recurring revenue.
- **Region / segment:** standardized casing and mapped NULL/unknown to `Unknown`.

## Modeling approach
Layered **staging → intermediate → mart**. Staging only cleans, casts, and dedupes
(no business logic). The intermediate model builds the
customer-monthly revenue and assigns cohorts — this is where the business logic
lives. The mart computes the NRR ratio.

## Trade-offs & what you'd improve with more time
- **Gap smoothing:** because un-billed months count as 0, NRR dips and recovers
  around billing gaps. With more time I'd fill active-but-unbilled months with
  signed MRR, giving a smoother, more realistic curve.
- **More tests:** for revenue reconcilliation and catch any lost revenue because of joins. 
- **Extensions:** GRR alongside NRR to see how much we keep before upsell 
(pure churn and contraction); segment/region cuts.
