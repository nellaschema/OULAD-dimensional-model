# Architecture

![Final pipeline with validation gates and both dashboards](assets/final-pipeline-with-dq.svg)

```mermaid
flowchart LR
    CSV[OULAD CSVs] --> RAW[Bronze / Raw]
    RAW --> BRONZE_DQ[Bronze Validation]
    BRONZE_DQ --> CLEAN[Silver / Clean]
    CLEAN --> SILVER_DQ[Silver Validation]
    SILVER_DQ --> DBT[dbt mart: 5 dimensions + 2 facts]
    DBT --> GOLD_DQ[Gold Validation]
    GOLD_DQ --> ANALYTICS[Analytics and cohort models]
    ANALYTICS --> ANALYTICS_DQ[Analytics Validation + Accuracy]
    ANALYTICS_DQ --> BUSINESS[Metabase Business Dashboard]
    BRONZE_DQ --> DQ_RESULTS[DQ check results]
    SILVER_DQ --> DQ_RESULTS
    GOLD_DQ --> DQ_RESULTS
    ANALYTICS_DQ --> DQ_RESULTS
    DQ_RESULTS --> DQ_DASHBOARD[Data Quality Dashboard]
```

The dbt mart is the assignment implementation. The SQL under `src/03_gold/`
mirrors the same model for a Databricks-only demonstration runner.

Every transformed layer has a gate. The data-quality dashboard reads only the
Bronze, Silver, Gold, and Analytics validation outputs. The business dashboard
refreshes only after Analytics validation.

For the exact task sequence and dbt command, see `pipeline.md`.

OULAD is a fixed research snapshot, so deterministic full refresh is safer than
incremental state without a reliable source update timestamp. If recurring
files are introduced later, add batch metadata and process only affected keys.
