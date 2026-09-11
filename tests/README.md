# OULAD validation guide

This directory contains two complementary types of tests:

1. Databricks SQL validation suites persist operational results from Bronze,
   Silver, Gold, and Analytics.
2. dbt singular tests return violating Gold rows during `dbt build`.

Together they answer both questions raised by the assignment: whether the
pipeline finished and whether its outputs can be trusted.

## Validation order

| Suite | Run after | Main responsibility | Blocks on |
|---|---|---|---|
| `03_validate_bronze.sql` | Seven Bronze loads | File interpretation, source keys, domains, and approved snapshot volumes | Critical failures |
| `05_validate_silver.sql` | Seven Silver tables | Clean grains, conformed relationships, and score completeness | Critical failures |
| `08_validate_gold.sql` | dbt or SQL Gold build | Five dimensions, two facts, foreign keys, measures, and control totals | Critical failures |
| `13_validate_analytics.sql` | Four Analytics builds | Reporting grains and cross-layer reconciliation | Critical failures |
| `dbt/*.sql` | During `dbt build` | Row-level Gold business rules not fully expressed by generic schema tests | Any returned row |

## How persisted checks work

Every Databricks suite appends rows to
`ftw-week-07.05-data-quality.dq_check_results`. A row records the layer,
dataset, columns, expectation, quality dimension, severity, owner, counts,
score, and status for one rule in one run.

The common calculations are:

```text
passed_count = max(total_count - failed_count, 0)
failure_pct  = 100 * failed_count / total_count
score_pct    = 100 * passed_count / total_count
```

An empty required dataset is classified as `FAIL`. Otherwise a check fails when
its failure percentage exceeds its threshold. A nonzero count inside an allowed
threshold becomes `WARNING`; zero failures becomes `PASS`.

The last query in every suite uses `ASSERT_TRUE` over the current run. It stops
execution only when a `CRITICAL` check has status `FAIL`. Medium-severity issues
remain visible in the DQ dashboard without unnecessarily blocking the whole
homework pipeline.

## Why the suites are separated by layer

- Bronze checks whether the files were interpreted as expected; it does not
  repeat all downstream relationship joins.
- Silver checks whether cleaning produced unique, conformed entities and
  events.
- Gold checks dimensional keys and reconciles fact counts and measures with
  Silver before Catalog relationships are registered.
- Analytics checks dashboard grains and reconciles counts/sums across layers.

This hierarchy makes a failure easier to locate. If Bronze is already wrong,
Gold should not hide the problem by transforming it further.

## Snapshot baselines and known source conditions

Bronze volume checks use the approved supplied-file baselines:

| Dataset | Expected rows |
|---|---:|
| `courses` | 22 |
| `assessments` | 206 |
| `vle` | 6,364 |
| `student_info` | 32,593 |
| `student_registration` | 32,593 |
| `student_assessment` | 173,912 |
| `student_vle` | 10,655,280 |

The one-percent volume threshold is an operational alert for a deliberately
changed snapshot; the expected homework files should match exactly. If the
group intentionally replaces the source snapshot, review and update the
baselines rather than weakening the rules.

The source contains 173 missing assessment scores. They remain null because an
imputed score would invent academic performance. Silver monitors the null rate
with a one-percent threshold, so the supplied snapshot is expected to produce a
non-blocking warning rather than data loss.

Repeated Student VLE rows are expected at the raw event grain. Silver combines
them to one student + presentation + site + relative-day row and preserves the
total click sum. Gold and Analytics reconciliation checks prove that the
aggregation did not lose clicks.

## Quality dimensions

- **Completeness:** required data is present.
- **Validity:** values satisfy types, ranges, and accepted domains.
- **Uniqueness:** declared grains do not repeat.
- **Consistency / Referential integrity:** child rows resolve to their parents
  and denormalized keys agree.
- **Timeliness / Volume:** the static snapshot has the expected amount of data;
  event-arrival latency is not claimed.
- **Accuracy:** additive controls reconcile between pipeline layers. This is
  transformation accuracy, not proof against an external real-world truth
  source.

## How dbt singular tests work

A singular dbt test is written as a query that returns bad rows. Therefore:

- **PASS:** zero rows returned.
- **FAIL:** one or more rows returned for investigation.

`assert_assessment_measures.sql` checks score and weight bounds,
`assert_vle_measures.sql` checks positive click totals, and
`assert_fact_course_presentation_consistency.sql` verifies that the direct
course key on each fact agrees with its module-presentation dimension.

Generic not-null, unique, relationship, and accepted-value tests are declared
in `../models/mart/schema.yml` rather than duplicated here.

## When a test fails

1. Record the run ID, layer, dataset, check name, failed count, and expectation.
2. Query the affected source rows using the same predicate as the failed rule.
3. Determine whether the cause is source data, parsing, transformation logic,
   or an intentionally changed snapshot.
4. Fix the earliest responsible layer and rerun from that layer forward.
5. Do not remove `ASSERT_TRUE`, lower severity, or relax a threshold solely to
   make the dashboard green; document an approved rule change instead.

For the exact task order, see `../src/README.md` and `../docs/pipeline.md`.

## Preserved team validation work

`cleaning-validation.sql` and `cleaning-validation-explanation.ipynb` are kept
as the original team's Silver-validation contribution and learning record. The
final automated path runs `05_validate_silver.sql`, which writes to the governed
`05-data-quality` schema and follows the shared result format used by all four
layers. Keep the original files for authorship history; use the numbered suite
for the final pipeline run.
