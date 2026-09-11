# OULAD data-quality dashboard

Build this Metabase dashboard from the governed views in
`ftw-week-07.05-data-quality` after all four validation suites have run. The
nine ready-to-save questions are in
`metabase/data_quality_dashboard_queries.sql`.

## Required views

- `dq_latest_check_results`
- `dq_dashboard_overview`
- `dq_dashboard_canonical_dimensions`
- `dq_dashboard_dataset_scores`
- `dq_dashboard_problem_areas`
- `dq_dashboard_daily_history`
- `dq_dashboard_volume_history`

## Recommended cards

1. Weighted quality score, check pass rate, source rows processed, failed rule
   evaluations, and checks needing attention.
2. Completeness, Timeliness/Volume, Validity, Accuracy, Consistency, and
   Uniqueness.
3. PASS/WARNING/FAIL counts by validation suite.
4. Quality score by dataset.
5. Checks needing attention, with owner, threshold, and affected count.
6. Latest source-volume reconciliation.
7. Daily quality history after at least three distinct run dates exist.

The weighted score is a monitoring KPI based on rule evaluations. Always show
it beside status counts and affected counts so a small table and the large VLE
fact are not interpreted as equally sized problems.
