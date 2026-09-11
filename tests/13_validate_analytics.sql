-- Databricks notebook source
-- Name: 13 - Analytics Validation
-- Purpose: Validate reporting outputs and consolidate cross-layer Accuracy controls.
-- Grain: One row per data-quality check and validation-suite run.
-- Depends on: Valid Silver, Gold, and all four Analytics build files.
-- Produces: Append-only ANALYTICS rows in dq_check_results plus a blocking gate.
-- Why: A dashboard table can have valid columns yet still duplicate cohorts or
-- lose measures. Cross-layer controls prove reporting transformations preserved
-- the upstream population, outcomes, submissions, scores, and clicks.
-- Accuracy scope: Reconciliation proves transformation accuracy, not agreement
-- with an unavailable external real-world truth source.
-- Rerun behavior: A new UUID records each suite run.
-- Documentation: See tests/README.md and docs/validation.md.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';
DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`05-data-quality`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- The following control CTEs reduce each layer to additive counts and sums. The
-- checks later compare like-for-like metrics without joining row-level tables.
INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH silver_cohort AS (
  SELECT
    COUNT(*) AS row_count,
    SUM(studied_credits) AS studied_credits,
    COUNT_IF(final_result = 'Withdrawn') AS withdrawn_count,
    COUNT_IF(final_result = 'Fail') AS failed_count,
    COUNT_IF(final_result = 'Pass') AS passed_count,
    COUNT_IF(final_result = 'Distinction') AS distinction_count
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')
),
analytics_cohort AS (
  SELECT
    COUNT(*) AS row_count,
    SUM(studied_credits) AS studied_credits,
    SUM(withdrawn_count) AS withdrawn_count,
    SUM(failed_count) AS failed_count,
    SUM(passed_count) AS passed_count,
    SUM(distinction_count) AS distinction_count
  FROM IDENTIFIER(analytics_namespace || '.student_cohort')
),
silver_assessment AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT_IF(score IS NOT NULL) AS scored_count,
    COUNT_IF(score IS NULL) AS missing_score_count,
    SUM(COALESCE(score, 0)) AS score_sum
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
),
gold_assessment AS (
  SELECT
    COUNT(*) AS row_count,
    COUNT_IF(score IS NOT NULL) AS scored_count,
    COUNT_IF(score IS NULL) AS missing_score_count,
    SUM(COALESCE(score, 0)) AS score_sum
  FROM IDENTIFIER(mart_namespace || '.fact_assessments')
),
silver_vle AS (
  SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
  FROM IDENTIFIER(clean_namespace || '.student_vle_clean')
),
gold_vle AS (
  SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interactions')
),
analytics_outcomes AS (
  SELECT
    SUM(enrolled_students) AS enrolled_count,
    SUM(withdrawn_students) AS withdrawn_count,
    SUM(failed_students) AS failed_count,
    SUM(passed_students) AS passed_count,
    SUM(distinction_students) AS distinction_count
  FROM IDENTIFIER(analytics_namespace || '.learner_outcomes')
),
analytics_engagement AS (
  SELECT COUNT(*) AS cohort_count, SUM(total_clicks) AS click_sum
  FROM IDENTIFIER(analytics_namespace || '.student_engagement')
),
analytics_assessment AS (
  SELECT
    SUM(submission_count) AS submission_count,
    SUM(scored_submission_count) AS scored_count,
    SUM(missing_score_count) AS missing_score_count,
    SUM(score_sum) AS score_sum
  FROM IDENTIFIER(analytics_namespace || '.assessment_performance')
),
-- First validate each Analytics table's own grain and metric domains; then
-- compare additive controls between Silver, Gold, and Analytics.
checks AS (
  SELECT
    'student_cohort' AS dataset_name,
    'student_cohort_key, final_result, is_withdrawn' AS column_name,
    'student enrollment grain and outcome fields are valid' AS check_name,
    'VALIDITY' AS quality_dimension,
    'UNIQUE_ACCEPTED_VALUES_DERIVATION' AS check_type,
    'One row per student enrollment; outcome is accepted and withdrawal flag agrees' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'analytics' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(
      student_cohort_key IS NULL
      OR final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
      OR is_withdrawn IS NULL
      OR is_withdrawn <> (final_result = 'Withdrawn')
      OR enrollment_count <> 1
    ) + COUNT(*) - COUNT(DISTINCT student_cohort_key) AS failed_count
  FROM IDENTIFIER(analytics_namespace || '.student_cohort')

  UNION ALL

  SELECT
    'learner_outcomes' AS dataset_name,
    'module_presentation_key' AS column_name,
    'learner outcome metrics are complete and bounded' AS check_name,
    'VALIDITY' AS quality_dimension,
    'UNIQUE_RANGE_RECONCILIATION' AS check_type,
    'One row per presentation; outcomes equal enrollments; rates are between zero and one'
      AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'analytics' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(
      module_presentation_key IS NULL
      OR successful_outcome_rate NOT BETWEEN 0 AND 1
      OR withdrawal_rate NOT BETWEEN 0 AND 1
      OR enrolled_students <= 0
      OR withdrawn_students + failed_students + passed_students + distinction_students
        <> enrolled_students
    ) + COUNT(*) - COUNT(DISTINCT module_presentation_key) AS failed_count
  FROM IDENTIFIER(analytics_namespace || '.learner_outcomes')

  UNION ALL

  SELECT
    'student_engagement', 'student_cohort_key',
    'engagement rows reconcile with the supporting cohort',
    'CONSISTENCY', 'UNIQUE_VOLUME_RECONCILIATION',
    'One non-negative engagement row per student and presentation',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_cohort_key IS NULL OR active_days < 0 OR activities_used < 0 OR total_clicks < 0
    ) + COUNT(*) - COUNT(DISTINCT student_cohort_key)
      + ABS(
        COUNT(*) - (
          SELECT COUNT(*) FROM IDENTIFIER(analytics_namespace || '.student_cohort')
        )
      )
  FROM IDENTIFIER(analytics_namespace || '.student_engagement')

  UNION ALL

  SELECT
    'assessment_performance', 'module_presentation_key, assessment_type',
    'assessment metrics and additive controls are valid',
    'VALIDITY', 'UNIQUE_RANGE_RECONCILIATION',
    'One row per group; counters reconcile; rates are between zero and one',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      submission_count <= 0
      OR scored_submission_count + missing_score_count <> submission_count
      OR passed_submission_count > scored_submission_count
      OR dated_submission_count > submission_count
      OR late_submission_count > dated_submission_count
      OR average_score IS NULL OR average_score NOT BETWEEN 0 AND 100
      OR pass_rate IS NULL OR pass_rate NOT BETWEEN 0 AND 1
      OR late_submission_rate NOT BETWEEN 0 AND 1
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(module_presentation_key, assessment_type))
      AS failed_count
  FROM IDENTIFIER(analytics_namespace || '.assessment_performance')

  UNION ALL

  SELECT
    'at_risk_students', 'student_cohort_key',
    'risk rows reconcile with the supporting cohort',
    'CONSISTENCY', 'UNIQUE_ACCEPTED_VALUES_VOLUME_RECONCILIATION',
    'One LOW, MEDIUM, or HIGH screening row per student and presentation',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      student_cohort_key IS NULL OR risk_score < 0 OR risk_score > 5
      OR risk_level NOT IN ('LOW', 'MEDIUM', 'HIGH')
    ) + COUNT(*) - COUNT(DISTINCT student_cohort_key)
      + ABS(
        COUNT(*) - (
          SELECT COUNT(*) FROM IDENTIFIER(analytics_namespace || '.student_cohort')
        )
      )
  FROM IDENTIFIER(analytics_namespace || '.at_risk_students')

  UNION ALL

  SELECT
    'student_cohort_pipeline', 'row_count, studied_credits, outcome counts',
    'Silver cohort controls reconcile with Analytics',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Six cohort controls are unchanged from Silver to the supporting Analytics model',
    0, 'CRITICAL', 'analytics', 6,
    CASE WHEN silver.row_count <> analytics.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.studied_credits <> analytics.studied_credits THEN 1 ELSE 0 END
      + CASE WHEN silver.withdrawn_count <> analytics.withdrawn_count THEN 1 ELSE 0 END
      + CASE WHEN silver.failed_count <> analytics.failed_count THEN 1 ELSE 0 END
      + CASE WHEN silver.passed_count <> analytics.passed_count THEN 1 ELSE 0 END
      + CASE WHEN silver.distinction_count <> analytics.distinction_count THEN 1 ELSE 0 END
  FROM silver_cohort AS silver
  CROSS JOIN analytics_cohort AS analytics

  UNION ALL

  SELECT
    'assessment_pipeline', 'row_count, scored_count, missing_score_count, score_sum',
    'Silver assessment controls reconcile with Gold',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Four assessment controls are unchanged from Silver to fact_assessments',
    0, 'CRITICAL', 'data_engineering', 4,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.scored_count <> gold.scored_count THEN 1 ELSE 0 END
      + CASE WHEN silver.missing_score_count <> gold.missing_score_count THEN 1 ELSE 0 END
      + CASE WHEN silver.score_sum <> gold.score_sum THEN 1 ELSE 0 END
  FROM silver_assessment AS silver
  CROSS JOIN gold_assessment AS gold

  UNION ALL

  SELECT
    'vle_pipeline', 'row_count, sum_click',
    'Silver VLE controls reconcile with Gold',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'VLE row count and click total are unchanged in fact_vle_interactions',
    0, 'CRITICAL', 'data_engineering', 2,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.click_sum <> gold.click_sum THEN 1 ELSE 0 END
  FROM silver_vle AS silver
  CROSS JOIN gold_vle AS gold

  UNION ALL

  SELECT
    'learner_outcomes', 'enrollment and outcome counts',
    'Cohort controls reconcile with learner outcomes',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Five cohort controls are unchanged in learner_outcomes',
    0, 'CRITICAL', 'analytics', 5,
    CASE WHEN cohort.row_count <> outcomes.enrolled_count THEN 1 ELSE 0 END
      + CASE WHEN cohort.withdrawn_count <> outcomes.withdrawn_count THEN 1 ELSE 0 END
      + CASE WHEN cohort.failed_count <> outcomes.failed_count THEN 1 ELSE 0 END
      + CASE WHEN cohort.passed_count <> outcomes.passed_count THEN 1 ELSE 0 END
      + CASE WHEN cohort.distinction_count <> outcomes.distinction_count THEN 1 ELSE 0 END
  FROM analytics_cohort AS cohort
  CROSS JOIN analytics_outcomes AS outcomes

  UNION ALL

  SELECT
    'student_engagement', 'cohort_count, total_clicks',
    'Gold and cohort controls reconcile with engagement Analytics',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Cohort count and Gold click total are unchanged in student_engagement',
    0, 'CRITICAL', 'analytics', 2,
    CASE WHEN cohort.row_count <> engagement.cohort_count THEN 1 ELSE 0 END
      + CASE WHEN vle.click_sum <> engagement.click_sum THEN 1 ELSE 0 END
  FROM analytics_cohort AS cohort
  CROSS JOIN gold_vle AS vle
  CROSS JOIN analytics_engagement AS engagement

  UNION ALL

  SELECT
    'assessment_performance',
    'submission_count, scored_count, missing_score_count, score_sum',
    'Gold controls reconcile with assessment performance',
    'ACCURACY', 'CONTROL_TOTAL_RECONCILIATION',
    'Four Gold assessment controls are unchanged in assessment_performance',
    0, 'CRITICAL', 'analytics', 4,
    CASE WHEN gold.row_count <> analytics.submission_count THEN 1 ELSE 0 END
      + CASE WHEN gold.scored_count <> analytics.scored_count THEN 1 ELSE 0 END
      + CASE WHEN gold.missing_score_count <> analytics.missing_score_count THEN 1 ELSE 0 END
      + CASE WHEN gold.score_sum <> analytics.score_sum THEN 1 ELSE 0 END
  FROM gold_assessment AS gold
  CROSS JOIN analytics_assessment AS analytics
),
-- Convert issue/control counts to comparable percentages for the DQ dashboard.
scored AS (
  SELECT
    *,
    CAST(
      CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END
      AS DECIMAL(7, 3)
    ) AS failure_pct,
    CAST(
      CASE WHEN total_count = 0 THEN 0.0
        ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count END
      AS DECIMAL(7, 3)
    ) AS score_pct
  FROM checks
),
-- Analytics uses zero tolerance for critical grain and reconciliation defects.
classified AS (
  SELECT
    *,
    CASE
      WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'
      WHEN failed_count > 0 THEN 'WARNING'
      ELSE 'PASS'
    END AS status
  FROM scored
)
SELECT
  dq_run_id, dq_executed_at, 'ANALYTICS', dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity, check_owner,
  total_count, failed_count, GREATEST(total_count - failed_count, 0),
  score_pct, failure_pct, status
FROM classified;

-- Stop downstream dashboard refresh when this run contains a critical failure.
SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Analytics data-quality check failed; inspect dq_check_results'
  ) AS analytics_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'ANALYTICS'
ORDER BY dataset_name, check_name;
