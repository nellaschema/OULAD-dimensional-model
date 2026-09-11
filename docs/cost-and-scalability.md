# Cost and scalability

The current design targets Databricks Free Edition and the fixed OULAD snapshot while keeping a clear path to larger recurring loads.

## Current choices

| Choice | Cost and reliability reason |
| --- | --- |
| dbt on Databricks SQL | dbt supplies mart lineage and tests while Databricks handles relational execution without a separate Spark application |
| Explicit `read_files` schemas | Avoids schema-inference scans and exposes malformed values through `_rescued_data` |
| Deterministic full refresh | Simple and reproducible for a fixed research snapshot; avoids incremental-state complexity |
| VLE aggregation in Silver | Reduces 10,655,280 source rows to the declared 8,459,320 daily fact grain before Gold and dashboard queries |
| Two conformed direct-key facts | Matches the assignment, prevents snowball joins, and simplifies BI query plans |
| Compact DQ result rows | Stores one summary per check rather than copying failed source datasets into the monitoring layer |
| Fail early by layer | Stops downstream table and dashboard work after a critical upstream failure |
| No automatic `OPTIMIZE` step | Avoids recurring maintenance cost before query history proves it is needed |

Production transformations use explicit columns rather than `SELECT *`. Queries should filter early, aggregate at the required grain, reuse Analytics tables for recurring dashboard logic, and avoid collecting row-level VLE data when a summary answers the question.

## When the source starts changing

Keep the current full-refresh design while the seven OULAD files remain a fixed snapshot. If new files begin arriving regularly:

1. Change Bronze ingestion to idempotent `COPY INTO` with file history.
2. Add batch identifiers and ingestion timestamps to the quality results.
3. Process only affected partitions or keys in Silver and Gold.
4. Review query history before adding liquid clustering to large event tables.
5. Preserve the same layer gates and append-only quality history.

Do not introduce streaming, orchestration services, or extra copies until freshness requirements and measured volume justify them.
