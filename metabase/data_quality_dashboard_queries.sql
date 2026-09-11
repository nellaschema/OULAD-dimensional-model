-- Metabase DQ question 1: Latest quality KPI cards
SELECT
  last_checked_at,
  weighted_quality_score_pct,
  check_pass_rate_pct,
  source_rows_processed,
  failed_rule_evaluations,
  checks_needing_attention,
  total_checks,
  passed_checks,
  warning_checks,
  failed_checks,
  critical_failures,
  validation_suites_checked,
  datasets_checked
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_overview;

-- Metabase DQ question 2: Six canonical quality dimensions
SELECT
  dimension_order,
  dimension_label,
  weighted_quality_score_pct,
  measurement_status,
  measurement_note,
  total_checks,
  warning_checks,
  failed_checks,
  failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_canonical_dimensions
ORDER BY dimension_order;

-- Metabase DQ question 3: Current validation-suite scores
SELECT
  layer AS validation_suite,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS failed_rule_evaluations,
  ROUND(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0), 3)
    AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_latest_check_results
WHERE 1 = 1
  [[AND {{validation_suite}}]]
  [[AND {{quality_dimension}}]]
  [[AND {{status}}]]
GROUP BY layer
ORDER BY layer;

-- Metabase DQ question 4: Dataset quality scores
SELECT
  layer AS validation_suite,
  dataset_name,
  weighted_quality_score_pct,
  total_checks,
  passed_checks,
  warning_checks,
  failed_checks,
  failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_dataset_scores
WHERE 1 = 1
  [[AND {{validation_suite}}]]
  [[AND {{dataset_name}}]]
ORDER BY layer, weighted_quality_score_pct, dataset_name;

-- Metabase DQ question 5: Latest check-status distribution
SELECT
  status,
  COUNT(*) AS check_count
FROM `ftw-week-07`.`05-data-quality`.dq_latest_check_results
WHERE 1 = 1
  [[AND {{validation_suite}}]]
  [[AND {{dataset_name}}]]
  [[AND {{quality_dimension}}]]
GROUP BY status
ORDER BY CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END;

-- Metabase DQ question 6: Checks needing attention
SELECT
  status,
  severity,
  layer AS validation_suite,
  dataset_name,
  column_name,
  check_name,
  quality_dimension,
  failed_count,
  failure_pct,
  threshold_pct,
  expectation,
  check_owner,
  executed_at
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_problem_areas
WHERE 1 = 1
  [[AND {{validation_suite}}]]
  [[AND {{dataset_name}}]]
  [[AND {{quality_dimension}}]]
  [[AND {{status}}]]
  [[AND {{severity}}]]
  [[AND {{check_owner}}]]
ORDER BY
  CASE status WHEN 'FAIL' THEN 1 ELSE 2 END,
  CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
  failed_count DESC;

-- Metabase DQ question 7: Checks needing attention by owner
SELECT
  check_owner,
  COUNT(*) AS checks_needing_attention,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  SUM(failed_count) AS failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_problem_areas
WHERE 1 = 1
  [[AND {{validation_suite}}]]
  [[AND {{dataset_name}}]]
  [[AND {{quality_dimension}}]]
  [[AND {{status}}]]
GROUP BY check_owner
ORDER BY failed_checks DESC, warning_checks DESC;

-- Metabase DQ question 8: Latest source-volume controls
WITH ranked_volume AS (
  SELECT
    executed_at,
    dataset_name,
    observed_row_count,
    difference_from_baseline,
    status,
    expectation,
    ROW_NUMBER() OVER (
      PARTITION BY dataset_name
      ORDER BY executed_at DESC, run_id DESC
    ) AS volume_rank
  FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_volume_history
  WHERE layer = 'BRONZE'
)
SELECT
  executed_at,
  dataset_name,
  observed_row_count,
  difference_from_baseline,
  status,
  expectation
FROM ranked_volume
WHERE volume_rank = 1
ORDER BY observed_row_count DESC;

-- Metabase DQ question 9: Daily history; display after at least three run dates exist
SELECT
  run_date,
  weighted_quality_score_pct,
  total_checks,
  warning_checks,
  failed_checks,
  failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_daily_history
WHERE run_date >= ADD_MONTHS(CURRENT_DATE(), -12)
ORDER BY run_date;
