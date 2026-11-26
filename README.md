# data-transform

dbt project for the Maison Douce Bakery data platform. Dagu clones this repo at run time and runs dbt (there is no image).

`profiles.yml` reads `DBT_HOST`, `DBT_PORT` (default 5432), `DBT_USER`, `DBT_PASSWORD` and `DBT_DBNAME`.

Parse locally: `pip install -r requirements.txt`, then `DBT_HOST=localhost DBT_USER=x DBT_PASSWORD=x DBT_DBNAME=x dbt parse`
