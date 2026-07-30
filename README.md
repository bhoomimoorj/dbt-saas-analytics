# Subscription Cohort NRR — a dbt + DuckDB project

A dbt project that models **cohort-based Net Revenue Retention (NRR)** from
three messy, realistic SaaS source systems (CRM, billing, customer dimension).
It's built to show how I approach analytics engineering end to end: spotting
data-quality problems, making explicit modeling decisions, and proving
correctness with tests rather than eyeballing the output.

## Why NRR

Net Revenue Retention answers a simple but important question: *for customers
who joined in a given month (a cohort), how does their recurring revenue
evolve afterward* — including expansion (upsells), contraction, and churn, but
excluding revenue from brand-new customers. It's one of the most closely
watched metrics in subscription businesses, and it's a good test of modeling
skill because the "right" grain, revenue basis, and churn definition aren't
handed to you — they have to be reasoned out from the data.

## Tech stack

- **[dbt](https://www.getdbt.com/)** for transformation, testing, and
  documentation
- **[DuckDB](https://duckdb.org/)** as the local, zero-setup database — no
  warehouse or credentials required, so anyone can clone this and run it
  immediately

## Quick start

```bash
# 1. create a virtual environment
python3 -m venv .venv && source .venv/bin/activate

# 2. install pinned dependencies
pip install -r requirements.txt

# 3. point dbt at the profile in this repo
export DBT_PROFILES_DIR=$(pwd)

# 4. load the seed data, build every model, and run every test
dbt build
```

> On Windows / PowerShell, replace step 3 with:
> `$env:DBT_PROFILES_DIR = (Get-Location).Path`

Dependency versions are pinned exactly (`dbt-core==1.11.2`,
`dbt-duckdb==1.10.1`) rather than left open-ended, so the build is
reproducible regardless of what's newest on install day.

## The data

Three CSV seeds in `seeds/`, deliberately messy the way real source systems
are:

| File | Source system | What it represents |
|------|---------------|--------------------|
| `crm_subscriptions.csv` | CRM (Salesforce-like) | Contracts with **signed** MRR, plan, start/end, status |
| `billing_invoices.csv` | Billing/Invoicing | Monthly **actual** invoiced amounts per subscription |
| `dim_customers.csv` | CRM | Customer attributes: region, segment, signup date |

Traps in the data that the model deliberately handles: duplicate and
conflicting rows, inconsistent casing and mixed grains in `region`/`segment`
(`DE` vs `Germany` vs `DACH`), a NULL/mis-cased `status`, customers with
multiple contracts including a mid-contract plan upgrade, negative invoices
(refunds/credits), signed MRR that doesn't match actual invoiced amounts, and
billing gaps on otherwise-active subscriptions.

## Project structure

```
models/
├── staging/        # clean, cast, dedupe — one model per source, no business logic
│   ├── stg_dim_customers.sql
│   ├── stg_crm_subscriptions.sql
│   └── stg_billing_invoices.sql
├── intermediate/    # business logic lives here
│   └── int_customer_monthly_revenue.sql   # customer-month revenue + cohort assignment
└── marts/
    └── nrr_by_cohort_month.sql            # final NRR ratio by cohort x months-since-start
```

Staging models are materialized as views (cheap pass-throughs); the mart is a
table (queried repeatedly, so it's pre-computed).

## Key decisions

Full reasoning is in [`DECISIONS.md`](DECISIONS.md). The short version:

- **Revenue basis:** actual invoiced amounts, not signed CRM MRR — NRR should
  reflect *realized* recurring revenue, not what was merely contracted.
- **Grain:** customer-month, rolled up from possibly-multiple subscriptions
  per customer, so a mid-contract upgrade reads as expansion rather than
  churn-plus-a-new-sale.
- **Cohort anchor:** each customer's first invoiced month, which guarantees a
  non-zero revenue base at month 0 (the NRR denominator).
- **Refunds:** netted against the same month's charges, then floored at 0 so
  a large refund can't push recurring revenue negative — which means modeled
  totals intentionally don't tie exactly to raw invoiced revenue.

## Testing

Generic tests (`unique`, `not_null`, `relationships`, `accepted_values`)
enforce keys, referential integrity, and the value domains created during
cleaning. Singular tests in `tests/` go further:

- `month0_nrr_is_one.sql` — every cohort must start at exactly 100% retention
- `unique_customer_month.sql` / `unique_cohort_period.sql` — grain checks at
  each layer
- `no_customers_dropped.sql` / `no_cohorts_dropped.sql` — nothing silently
  disappears across a join
- `no_revenue_lost.sql` — a directional reconciliation check: the floor can
  only add revenue back, so modeled totals should never fall *below* raw
  invoiced revenue

Run everything with `dbt build`, or just the tests with `dbt test`.

## What's next

This project is a work in progress. Planned additions:

- A calendar-time trailing-twelve-month NRR trend (the board-level metric,
  distinct from the cohort-relative curves here)
- Gross Revenue Retention (GRR) alongside NRR to separate pure retention from
  expansion
- Segment/region cuts of the metric
- A written analysis of what the numbers show, not just the model that
  produces them
- Reusable macros for the repeated staging cleanup logic
- Full column-level documentation for a browsable `dbt docs` lineage graph
- CI that runs `dbt build` on every push
