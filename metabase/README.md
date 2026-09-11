# Metabase dashboard build guide

The business dashboard uses validated tables in `ftw-week-07.04-analytics`.
The Data Quality dashboard uses governed views in
`ftw-week-07.05-data-quality`. The two dashboard Markdown files under
`dashboard/` provide the assignment-to-card mapping; Metabase is the required
presentation layer.

## Connect the data

1. Add the Databricks SQL warehouse as a Metabase database.
2. Synchronize schemas `03-mart`, `04-analytics`, and `05-data-quality`.
3. Create a collection named **OULAD Student Performance & Engagement**.
4. Save each statement from `dashboard_queries.sql`. Use queries 1 and 2 as
   source models for the KPI number cards; create one number question per metric.

## Dashboard layout

| Row | Card | Visualization |
|---:|---|---|
| 1 | Total Enrollments, Successful Outcome Rate, Withdrawal Rate, Average Score | Number cards |
| 2 | Enrollment Outcomes by Module Presentation | Stacked bar |
| 2 | Top Withdrawal-Rate Presentations | Horizontal bar |
| 3 | Engagement by Final Result | Grouped bar |
| 3 | Weekly VLE Activity | Line chart |
| 4 | Assessment Performance by Type | Grouped/combo chart |
| 4 | Late Submission Rate | Horizontal bar |
| 5 | Withdrawal Rate by Age Band | Horizontal bar |
| 5 | Rule-Based Risk Distribution | Stacked bar |

## Filters

Add `code_module` and `code_presentation` as dashboard-wide filters. Add
`assessment_type`, `final_result`, and `risk_level` only to cards containing
those fields. In every saved SQL question, configure these variables as
**Field Filters** and map each one to the same-named column in that question's
base table. Empty selections mean **All**.

Rates must be calculated from additive totals. Do not average stored rates.
Risk is a transparent screening rule, not a trained prediction. Negative
relative weeks are valid pre-presentation activity and must remain visible.

## Data Quality dashboard

Create a second collection named **OULAD Data Quality Monitoring**. Save the
nine statements in `data_quality_dashboard_queries.sql` as separate questions.

| Row | Card | Visualization |
|---:|---|---|
| 1 | Weighted DQ Score, Check Pass Rate, Source Rows, Failed Evaluations | Number cards |
| 2 | Six Canonical Quality Dimensions | Bar/table |
| 3 | Current Validation-Suite Scores | Bar chart |
| 3 | Latest Check-Status Distribution | Stacked bar or donut |
| 4 | Dataset Quality Scores | Table |
| 5 | Checks Needing Attention | Detail table |
| 6 | Checks Needing Attention by Owner | Bar chart |
| 6 | Latest Source-Volume Controls | Table |
| 7 | Daily Quality History | Line chart; show only after three run dates |

Map `validation_suite`, `dataset_name`, `quality_dimension`, `status`,
`severity`, and `check_owner` as Field Filters only on compatible cards. The DQ
dashboard reads the centralized check-result table through governed views; it
does not rerun validation itself.
