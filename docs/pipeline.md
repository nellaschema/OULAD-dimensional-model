# Databricks + dbt pipeline

The production path is a gated sequence. A failed validation task stops all
downstream work; every validation writes its result to
`ftw-week-07.05-data-quality.dq_check_results`.

| Order | Databricks task | Runs | Depends on |
|---:|---|---|---|
| 1 | `bronze_and_raw_validation` | `notebooks/01_bronze_oulad.sql` | — |
| 2 | `silver_and_silver_validation` | `notebooks/02_silver_oulad.sql` | Task 1 succeeded |
| 3 | `dbt_mart` | `dbt build --select path:models/mart` | Task 2 succeeded |
| 4 | `mart_analytics_and_validation` | `notebooks/06_run_after_dbt.sql` | Task 3 succeeded |

Task 3 is where dbt creates and tests the five dimensions and two facts in
`ftw-week-07.03-mart`. dbt is therefore the mart implementation—not a step
after a separately built mart.

Task 4 performs the remaining logical stages in this order:

1. Mart validation and relationship registration.
2. Analytics/cohort model creation.
3. Analytics and cross-layer Accuracy validation.
4. Data-quality and governed dashboard-view refresh.

After Task 4 succeeds, Metabase reads two separate outputs:

- Business dashboard: `ftw-week-07.04-analytics`.
- Data Quality dashboard: `ftw-week-07.05-data-quality`.

## Configure the dbt task

Use the Git repository root as the dbt project directory. Copy
`profiles.yml.example` to the dbt profile location, then provide these secrets
as environment variables:

```text
DATABRICKS_HOST
DATABRICKS_HTTP_PATH
DATABRICKS_TOKEN
```

Install and verify locally or in the job environment:

```bash
python3 -m pip install -r requirements-dbt.txt
dbt debug
dbt build --select path:models/mart
```

Configure every task to run as a principal that has `USE CATALOG` on
`ftw-week-07`, `SELECT` on `01-raw` and `02-clean`, and create/modify/select
permissions on `03-mart`, `04-analytics`, and `05-data-quality`.

## Failure behavior

- Raw failure: stop before Silver.
- Silver failure: stop before dbt.
- dbt model or test failure: stop before Analytics.
- Mart or Analytics validation failure: do not refresh the business dashboard.
- All completed validation results remain available to the Data Quality
  dashboard for investigation.

`notebooks/00_run_full_pipeline.sql` remains a Databricks-only demonstration
runner. It uses the SQL mirror for the mart; the assessed implementation is the
dbt path above.
