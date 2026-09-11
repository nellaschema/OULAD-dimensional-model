# Assignment handoff

This package extends the group repository without deleting the original team
queries. Their SQL bodies remain under the original `src/ingestion/`,
`src/cleaning/`, `src/mart/`, `src/data-quality/`, and
`tests/cleaning-validation.sql` paths. Short header comments point to the final
ordered implementation.

## What was added or corrected

- An ordered Databricks pipeline for Setup, Bronze, Silver, Gold, Analytics,
  and Data Quality.
- A dbt mart with exactly five dimensions and two facts, plus relationship,
  uniqueness, not-null, accepted-value, and business-rule tests.
- A persisted `dq_check_results` framework, blocking critical gates, weighted
  quality scores, history views, and a trust dashboard query pack.
- Metabase-ready business questions for engagement, performance, withdrawal,
  course activity, cohort comparison, and proactive at-risk support.
- Source profiling and explicit CSV schemas for all seven supplied files.
- Documentation covering architecture, grains and keys, assumptions, DQ
  methodology, run order, scalability, validation, and dashboard setup.
- CI checks for repository contracts and offline dbt parsing.
- The supplied final pipeline and star-schema SVGs under `docs/assets/`.

Corrections made while integrating the reference implementation include the
source-volume path spelling, the positional assessment CSV schema, Gold
relationship registration order, enforced Gold failure assertions, and keeping
enrollment outcomes out of the demographic dimension.

## Before the group submits

1. Review `README.md` and `docs/pipeline.md`.
2. Confirm the Unity Catalog source path and permissions in
   `src/00_setup/01_setup.sql`.
3. Configure `profiles.yml` from `profiles.yml.example` without committing
   credentials.
4. Run the Databricks + dbt sequence and keep screenshots of the passing DQ
   gates and both Metabase dashboards.
5. Add each group member's changes through branches or pull requests so the Git
   history shows meaningful contributions.

The CSV data and credentials are intentionally excluded from this package.
