# Data quality methodology

## Quality contract

Every validation suite appends one row per rule to `ftw-week-07.05-data-quality.dq_check_results`. A result records its suite, dataset, column, quality dimension, rule type, expectation, threshold, severity, owner, evaluated count, failed count, score, status, timestamp, and suite run ID.

Each suite generates its own run ID. Current dashboard state is therefore the latest completed run **per validation suite**, not one global latest run.

## Dimensions

| Dimension | OULAD interpretation |
|---|---|
| Completeness | Required values and monitored optional values |
| Timeliness / Volume | Static-snapshot source-volume proxy; event latency is not available |
| Validity | Types, ranges, accepted values, and business rules |
| Accuracy | Cross-layer control-total reconciliation; not external truth |
| Consistency | Relationships and logically consistent values, including referential integrity |
| Uniqueness | Declared natural and fact grains |

## Status rules

- `PASS`: zero failed evaluations.
- `WARNING`: failures exist but the failure percentage is within the allowed threshold.
- `FAIL`: failure percentage exceeds the threshold or the evaluated dataset is empty.
- Only a `CRITICAL` FAIL blocks downstream processing.

The 173 null assessment scores are part of the published source. They remain null and create one MEDIUM-severity WARNING within a one-percent threshold.

## Scoring

```text
weighted quality score = 100 * sum(passed_count) / sum(total_count)
check pass rate = 100 * count(PASS checks) / count(all checks)
```

The weighted score describes rule-evaluation coverage and is dominated by high-volume checks. It must be displayed with three decimals and accompanied by status/check counts. It is a monitoring KPI, not proof that data is true.

## Layer gates

| Suite | Main purpose | Blocking examples |
|---|---|---|
| Bronze | Source contracts, parsing, keys, domains, source volume | Missing keys, invalid required values, duplicate source grains |
| Silver | Clean grains and conformed source relationships | Broken relationships or duplicate clean grains |
| Gold | Dimension/fact grains and direct conformed keys | Orphan facts, duplicate fact keys, invalid measures |
| Analytics | Reporting grains, counters, bounds, enrollment reconciliation, and Silver→Gold→Analytics Accuracy | Duplicate output grains, inconsistent counters, or changed row counts, outcome counts, scores, or click totals |

## History

Raw check history is append-only. Daily dashboard history selects the latest completed run for each suite on each day before aggregating. A trend should be displayed only after at least three distinct run dates exist.
