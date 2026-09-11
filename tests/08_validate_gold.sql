-- Databricks notebook source
-- DBTITLE 1,Cell 1
-- Name: 08 - Gold Validation
-- Purpose: Validate exactly five dimensions and two facts before registering relationships.
-- Grain: One row per data-quality check and pipeline run.
-- Depends on: The complete dbt mart or SQL compatibility Gold build.
-- Produces: Append-only GOLD rows in dq_check_results plus a blocking gate.
-- Why: Databricks PK/FK declarations are informational, so actual uniqueness,
-- referential integrity, measure ranges, and control totals must be queried.
-- Rerun behavior: A new UUID records each validation attempt.
-- Expected: Five dimension checks, two fact checks, and reconciliation controls
-- pass before 08_gold_relationships.sql registers catalog metadata.
-- Documentation: See tests/README.md and docs/validation.md.

DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Dimension branches test declared grains; fact branches test all direct
-- dimension keys and measures. Final branches reconcile Gold with Silver.
INSERT INTO `ftw-week-07`.`04-analytics`.dq_check_results
WITH checks AS (
  SELECT
    'dim_student' AS dataset_name, 'student_key' AS column_name,
    'student key is complete and unique' AS check_name,
    'UNIQUENESS' AS quality_dimension, 'NULL_UNIQUE' AS check_type,
    'One non-null key per student' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct, 'CRITICAL' AS severity,
    'data_engineering' AS check_owner, COUNT(*) AS total_count,
    COUNT_IF(student_key IS NULL OR id_student IS NULL)
      + COUNT(*) - COUNT(DISTINCT student_key) AS failed_count
  FROM `ftw-week-07`.`03-mart`.dim_student

  UNION ALL

  SELECT
    'dim_course', 'course_key', 'course key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per code_module',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course_key IS NULL OR code_module IS NULL)
      + COUNT(*) - COUNT(DISTINCT course_key)
  FROM `ftw-week-07`.`03-mart`.dim_course

  UNION ALL

  SELECT
    'dim_module_presentation', 'module_presentation_key, course_key',
    'module presentation grain and course key are valid',
    'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One presentation row with a valid course key',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.course_key IS NULL OR presentation.module_presentation_key IS NULL)
      + COUNT(*) - COUNT(DISTINCT presentation.module_presentation_key)
  FROM `ftw-week-07`.`03-mart`.dim_module_presentation AS presentation
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_course AS course
    ON presentation.course_key = course.course_key

  UNION ALL

  SELECT
    'dim_date', 'date_key', 'relative date key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE', 'One non-null key per relative course day',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(date_key IS NULL OR relative_day IS NULL)
      + COUNT(*) - COUNT(DISTINCT date_key)
  FROM `ftw-week-07`.`03-mart`.dim_date

  UNION ALL

  SELECT
    'dim_demographics', 'demographics_key',
    'demographic profile key is complete and unique',
    'UNIQUENESS', 'NULL_UNIQUE',
    'One non-null key per distinct demographic profile',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(demographics_key IS NULL)
      + COUNT(*) - COUNT(DISTINCT demographics_key)
  FROM `ftw-week-07`.`03-mart`.dim_demographics

  UNION ALL

  SELECT
    'fact_assessments', 'assessment_submission_key',
    'assessment fact grain and dimension keys are valid',
    'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One submission with valid student, course, presentation, demographics, and relative dates',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      student.student_key IS NULL OR course.course_key IS NULL
      OR presentation.module_presentation_key IS NULL
      OR demographic.demographics_key IS NULL OR submission_date.date_key IS NULL
      OR (fact.due_date_key IS NOT NULL AND due_date.date_key IS NULL)
      OR fact.course_key <> presentation.course_key
      OR fact.score < 0 OR fact.score > 100
      OR fact.assessment_weight < 0 OR fact.assessment_weight > 100
    ) + COUNT(*) - COUNT(DISTINCT fact.assessment_submission_key)
  FROM `ftw-week-07`.`03-mart`.fact_assessments AS fact
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_student AS student
    ON fact.student_key = student.student_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_course AS course
    ON fact.course_key = course.course_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS presentation
    ON fact.module_presentation_key = presentation.module_presentation_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics AS demographic
    ON fact.demographics_key = demographic.demographics_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_date AS submission_date
    ON fact.submission_date_key = submission_date.date_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_date AS due_date
    ON fact.due_date_key = due_date.date_key

  UNION ALL

  SELECT
    'fact_vle_interactions', 'vle_interaction_key',
    'VLE fact grain and dimension keys are valid',
    'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One student-site-day row with valid student, course, presentation, demographics, and date',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      student.student_key IS NULL OR course.course_key IS NULL
      OR presentation.module_presentation_key IS NULL
      OR demographic.demographics_key IS NULL OR activity_date.date_key IS NULL
      OR fact.course_key <> presentation.course_key OR fact.sum_click <= 0
    ) + COUNT(*) - COUNT(DISTINCT fact.vle_interaction_key)
  FROM `ftw-week-07`.`03-mart`.fact_vle_interactions AS fact
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_student AS student
    ON fact.student_key = student.student_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_course AS course
    ON fact.course_key = course.course_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS presentation
    ON fact.module_presentation_key = presentation.module_presentation_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics AS demographic
    ON fact.demographics_key = demographic.demographics_key
  LEFT JOIN `ftw-week-07`.`03-mart`.dim_date AS activity_date
    ON fact.activity_date_id = activity_date.date_key

  UNION ALL

  SELECT
    'fact_assessments', 'row_count', 'Gold assessments reconcile with Silver',
    'CONSISTENCY', 'VOLUME_RECONCILIATION',
    'Gold assessment count equals clean submission count',
    0, 'CRITICAL', 'data_engineering',
    (SELECT COUNT(*) FROM `ftw-week-07`.`02-clean`.student_assessment_clean),
    ABS(
      (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.fact_assessments)
      - (SELECT COUNT(*) FROM `ftw-week-07`.`02-clean`.student_assessment_clean)
    )

  UNION ALL

  SELECT
    'fact_vle_interactions', 'row_count, sum_click', 'Gold VLE controls reconcile with Silver',
    'CONSISTENCY', 'CONTROL_TOTAL_RECONCILIATION',
    'Gold VLE row count and click total equal the clean daily interaction controls',
    0, 'CRITICAL', 'data_engineering', 2,
    CASE WHEN silver.row_count <> gold.row_count THEN 1 ELSE 0 END
      + CASE WHEN silver.click_sum <> gold.click_sum THEN 1 ELSE 0 END
  FROM (
    SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
    FROM `ftw-week-07`.`02-clean`.student_vle_clean
  ) AS silver
  CROSS JOIN (
    SELECT COUNT(*) AS row_count, SUM(sum_click) AS click_sum
    FROM `ftw-week-07`.`03-mart`.fact_vle_interactions
  ) AS gold
),
-- Calculate weighted failure and quality percentages from the common metrics.
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
-- Gold uses zero tolerance for every critical key, relationship, and control.
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
  dq_run_id, dq_executed_at, 'GOLD', dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity, check_owner,
  total_count, failed_count, GREATEST(total_count - failed_count, 0),
  score_pct, failure_pct, status
FROM classified;

-- Capture the session UUID in a one-row CTE, then block relationship
-- registration if any critical check from this exact run failed.
WITH current_run AS (
  SELECT dq_run_id AS current_run_id
)
SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  total_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Gold data-quality check failed; inspect 04-analytics.dq_check_results'
  ) AS gold_quality_gate
FROM `ftw-week-07`.`04-analytics`.dq_check_results
CROSS JOIN current_run
WHERE run_id = current_run.current_run_id AND layer = 'GOLD'
ORDER BY dataset_name, check_name;