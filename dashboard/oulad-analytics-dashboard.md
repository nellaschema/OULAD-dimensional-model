# OULAD business dashboard

Build this dashboard in Metabase after `notebooks/06_run_after_dbt.sql`
finishes successfully. The exact SQL for every card is in
`metabase/dashboard_queries.sql`; connection, filters, and layout instructions
are in `metabase/README.md`.

## Assignment questions covered

| Assignment question | Dashboard evidence |
|---|---|
| How does engagement relate to performance? | Engagement by Final Result; Observed Withdrawal Rate by Risk Level |
| What patterns appear among students who withdraw? | Enrollment Outcomes, Withdrawal Rate by Age Band, and Highest Withdrawal-Rate Presentations |
| How does activity change throughout a course? | Weekly VLE Activity, including valid negative pre-presentation weeks |
| What additional question helps the business? | Which transparent risk bands identify cohorts with higher observed withdrawal rates? |

## Recommended cards

1. Total enrollments, successful outcome rate, withdrawal rate, and average
   assessment score.
2. Enrollment outcomes by module presentation.
3. Engagement by final result.
4. Weekly VLE activity.
5. Assessment performance and late-submission rate.
6. Withdrawal rate by age band.
7. Rule-based risk distribution and observed withdrawal rate by risk level.

Use additive counts as the inputs to every rate. Do not average percentages
across modules. Label the risk result as a rule-based screening indicator, not
as a prediction.
