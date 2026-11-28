# data-transform

dbt project for the Maison Douce Bakery data platform. Dagu clones this repo at run time and runs dbt (there is no image).

`profiles.yml` reads `DBT_HOST`, `DBT_PORT` (default 5432), `DBT_USER`, `DBT_PASSWORD` `DBT_DBNAME` and `DBT_SSLMODE` (default `require`).

Run locally: `pip install -r requirements.txt`, set the `DBT_*` variables (`DBT_SSLMODE=disable` for a local Postgres), then `dbt deps && dbt build`.

## Layers

| Layer | Schema | Materialization | Content |
|---|---|---|---|
| staging | `staging` | table | 1:1 with each `bakery` table: renames and casts only, no filters, no history. `open_meteo` (schema `raw`, loaded by dlt) keeps only the latest revision of each hour |
| intermediate | `intermediate` | table | building blocks, not exposed |
| marts | `marts` | table | `dim_*`, `fct_*`, `rpt_*`, `bridge_*` |
| snapshots | `snapshots` | snapshot | SCD2 history for customers, products and employees |

Everything except snapshots is rebuilt from scratch on every run. `generate_schema_name` uses the schema names exactly, with no target prefix.

Run: `dbt deps`, then `dbt build` (seeds, staging, snapshots and marts in DAG order). The `dbt` role needs `TEMPORARY` on the database for snapshot updates.

## Rules

- Staging keeps soft-deleted rows and exposes `is_deleted`. Every model downstream of staging must exclude them (`where not is_deleted`). Type 1 dimensions keep deleted keys, flagged, so facts never lose their key.
- Audit columns are renamed to `created_at`, `updated_at`, `is_deleted`, `deleted_at`. The business `created_at` of `branches` and `products` becomes `branch_created_at` and `product_created_at`.
- Business dates come from `business_date(ts)` and `business_timestamp(ts)`, driven by the var `business_timezone`. Do not hard-code a timezone.
- Surrogate keys are `dbt_utils.generate_surrogate_key` hashes, never sequences.
- SCD2 dimensions (`dim_customers`, `dim_products`, `dim_employees`) have `valid_from` (first version `-infinity`), `valid_to` (`9999-12-31` for the current version) and `is_current`. Join facts as of event time: `event_ts >= valid_from and event_ts < valid_to`.
- Walk-in sales have a NULL `customer_sk` (no unknown-member row yet).
- Product category is a column of `dim_products` (current state, history not tracked), so there is no `dim_product_categories`.
- Folders: `models/staging/{bakery,open_meteo}`, `models/intermediate/<domain>`, `models/marts/dimensions`, `models/marts/{sales,inventory,procurement,finance,weather}`.

## Conventions

- Every `fct_*` and daily `rpt_*` has one primary pair `date_sk` (int) + `business_date` (date) for its primary event (sale: `sold_at`, payment: `paid_at`, PO line: order date, receipt line: received date, shift: `opened_at`, batch: start else completion else creation). Other dates keep a role prefix: `<role>_date` and `<role>_date_sk` (`expected_date`, `closed_date`, `sale_date`). As-of snapshots use `as_of_date`.
- SCD2 dimensions have `valid_from` / `valid_to` (timestamptz, as-of joins). Date-effective dimensions (`dim_recipes`, `dim_promotions`) have `effective_from` / `effective_to`.
- Money ends with `_amount` (ledger), `_price` (unit price), `_cost` (cost) or `_value` (inventory valuation). Quantities end with `_quantity`; a bare `quantity` or `amount` is the fact's own measure.
- Named exceptions: `average_order_value`, counts `*_count`, flags `is_*` / `has_*`, ratios `*_ratio` / `*_share`, loyalty points (`points_*`).
