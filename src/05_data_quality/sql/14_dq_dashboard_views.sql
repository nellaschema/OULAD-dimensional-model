-- Databricks notebook source
-- Name: 14 - Data Quality Dashboard Views
-- Purpose: Publish one current cross-suite snapshot plus historical DQ datasets.

-- Find the newest complete validation run independently for each layer. A
-- single global run_id cannot be used because suites execute at different times.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_latest_check_results AS
WITH validation_runs AS (
  SELECT
    layer,
    run_id,
    MAX(executed_at) AS run_executed_at
  FROM `ftw-week-07`.`04-analytics`.dq_check_results
  GROUP BY layer, run_id
),
ranked_runs AS (
  SELECT
    layer,
    run_id,
    run_executed_at,
    ROW_NUMBER() OVER (
      PARTITION BY layer
      ORDER BY run_executed_at DESC, run_id DESC
    ) AS run_rank
  FROM validation_runs
)
SELECT checks.*
FROM `ftw-week-07`.`04-analytics`.dq_check_results AS checks
INNER JOIN ranked_runs AS latest
  ON checks.layer = latest.layer
  AND checks.run_id = latest.run_id
WHERE latest.run_rank = 1;

-- One-row executive snapshot. weighted_quality_score_pct weights rules by their
-- evaluated row counts; check_pass_rate_pct weights every rule equally. Showing
-- both avoids hiding either widespread row defects or many small failed rules.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_overview AS
WITH latest_checks AS (
  SELECT
    executed_at,
    layer,
    dataset_name,
    check_type,
    severity,
    total_count,
    passed_count,
    failed_count,
    status
  FROM `ftw-week-07`.`04-analytics`.dq_latest_check_results
),
source_volume AS (
  SELECT COALESCE(SUM(total_count), 0) AS source_rows_processed
  FROM latest_checks
  WHERE layer = 'BRONZE' AND check_type = 'VOLUME'
)
SELECT
  MAX(executed_at) AS last_checked_at,
  CAST(
    100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0)
    AS DECIMAL(7, 3)
  ) AS weighted_quality_score_pct,
  CAST(
    100.0 * COUNT_IF(status = 'PASS') / NULLIF(COUNT(*), 0)
    AS DECIMAL(7, 3)
  ) AS check_pass_rate_pct,
  MAX(source_volume.source_rows_processed) AS source_rows_processed,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') AS critical_failures,
  COUNT_IF(status IN ('WARNING', 'FAIL')) AS checks_needing_attention,
  SUM(failed_count) AS failed_rule_evaluations,
  COUNT(DISTINCT layer) AS validation_suites_checked,
  COUNT(DISTINCT CONCAT(layer, '/', dataset_name)) AS datasets_checked
FROM latest_checks
CROSS JOIN source_volume;

-- Aggregate raw quality dimensions. Referential integrity is presented as
-- Consistency so dashboard labels remain understandable to nontechnical users.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_dimension_scores AS
WITH mapped AS (
  SELECT
    CASE
      WHEN quality_dimension = 'REFERENTIAL_INTEGRITY' THEN 'CONSISTENCY'
      ELSE quality_dimension
    END AS quality_dimension,
    executed_at,
    status,
    total_count,
    passed_count,
    failed_count
  FROM `ftw-week-07`.`04-analytics`.dq_latest_check_results
)
SELECT
  quality_dimension,
  CAST(
    100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0)
    AS DECIMAL(7, 3)
  ) AS weighted_quality_score_pct,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS failed_rule_evaluations,
  MAX(executed_at) AS last_checked_at
FROM mapped
GROUP BY quality_dimension;

-- Left join scores to a six-dimension catalog so an unmeasured dimension appears
-- as NOT_MEASURED instead of silently disappearing from the dashboard.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_canonical_dimensions AS
WITH dimension_catalog AS (
  SELECT dimension_order, dimension_key, dimension_label
  FROM VALUES
    (1, 'COMPLETENESS', 'Completeness'),
    (2, 'TIMELINESS_VOLUME', 'Timeliness / Volume'),
    (3, 'VALIDITY', 'Validity'),
    (4, 'ACCURACY', 'Accuracy'),
    (5, 'CONSISTENCY', 'Consistency'),
    (6, 'UNIQUENESS', 'Uniqueness')
    AS catalog(dimension_order, dimension_key, dimension_label)
)
SELECT
  catalog.dimension_order,
  catalog.dimension_key,
  catalog.dimension_label,
  scores.weighted_quality_score_pct,
  scores.total_checks,
  scores.passed_checks,
  scores.warning_checks,
  scores.failed_checks,
  scores.failed_rule_evaluations,
  CASE
    WHEN scores.quality_dimension IS NULL THEN 'NOT_MEASURED'
    ELSE 'MEASURED'
  END AS measurement_status,
  CASE
    WHEN catalog.dimension_key = 'ACCURACY' AND scores.quality_dimension IS NULL
      THEN 'N/A - transformation reconciliation has not run'
    WHEN catalog.dimension_key = 'ACCURACY'
      THEN 'Cross-layer transformation reconciliation; not external ground truth'
    WHEN catalog.dimension_key = 'TIMELINESS_VOLUME'
      THEN 'Source-volume proxy; event latency is not measured for this static snapshot'
    ELSE 'Directly measured by validation rules'
  END AS measurement_note
FROM dimension_catalog AS catalog
LEFT JOIN `ftw-week-07`.`04-analytics`.dq_dashboard_dimension_scores AS scores
  ON catalog.dimension_key = scores.quality_dimension;

-- Dataset-level scores help owners locate which layer and table need attention.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_dataset_scores AS
SELECT
  layer,
  dataset_name,
  CAST(
    100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0)
    AS DECIMAL(7, 3)
  ) AS weighted_quality_score_pct,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS failed_rule_evaluations,
  MAX(executed_at) AS last_checked_at
FROM `ftw-week-07`.`04-analytics`.dq_latest_check_results
GROUP BY layer, dataset_name;

-- Keep only warnings and failures for the actionable-problem table.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_problem_areas AS
SELECT
  executed_at,
  layer,
  dataset_name,
  column_name,
  check_name,
  quality_dimension,
  check_type,
  expectation,
  threshold_pct,
  severity,
  check_owner,
  total_count,
  failed_count,
  failure_pct,
  score_pct,
  status
FROM `ftw-week-07`.`04-analytics`.dq_latest_check_results
WHERE status IN ('WARNING', 'FAIL');

-- Keep the latest run per layer per day. This prevents repeated reruns on the
-- same day from being double counted in the quality trend.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_daily_history AS
WITH validation_runs AS (
  SELECT
    CAST(executed_at AS DATE) AS run_date,
    layer,
    run_id,
    MAX(executed_at) AS run_executed_at
  FROM `ftw-week-07`.`04-analytics`.dq_check_results
  GROUP BY CAST(executed_at AS DATE), layer, run_id
),
ranked_runs AS (
  SELECT
    run_date,
    layer,
    run_id,
    run_executed_at,
    ROW_NUMBER() OVER (
      PARTITION BY run_date, layer
      ORDER BY run_executed_at DESC, run_id DESC
    ) AS run_rank
  FROM validation_runs
),
daily_checks AS (
  SELECT latest.run_date, checks.*
  FROM `ftw-week-07`.`04-analytics`.dq_check_results AS checks
  INNER JOIN ranked_runs AS latest
    ON checks.layer = latest.layer
    AND checks.run_id = latest.run_id
  WHERE latest.run_rank = 1
)
SELECT
  run_date,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS failed_rule_evaluations,
  CAST(
    100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0)
    AS DECIMAL(7, 3)
  ) AS weighted_quality_score_pct
FROM daily_checks
GROUP BY run_date;

-- Volume history preserves the observed count and absolute difference from the
-- approved baseline for every Bronze volume check.
CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.dq_dashboard_volume_history AS
SELECT
  run_id,
  executed_at,
  layer,
  dataset_name,
  check_name,
  expectation,
  total_count AS observed_row_count,
  failed_count AS difference_from_baseline,
  status
FROM `ftw-week-07`.`04-analytics`.dq_check_results
WHERE check_type = 'VOLUME';