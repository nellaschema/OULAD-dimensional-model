-- Databricks notebook source
-- Name: 03 - Bronze Validation
-- Purpose: Persist source-level DQ results and stop on critical ingestion failures.
-- Grain: One row per data quality check and pipeline run.
-- Depends on: Setup and all seven Bronze tables.
-- Produces: Append-only BRONZE rows in dq_check_results plus a blocking gate.
-- Why: Typed ingestion can succeed even when keys, domains, volumes, or rescued
-- values are wrong; this suite proves the source contract before Silver begins.
-- Rerun behavior: A new UUID records a new validation run; history is preserved.
-- Expected: Critical checks pass for the supplied snapshot. Medium volume and
-- rescued-data checks stay visible without blocking unless marked CRITICAL.
-- Documentation: See tests/README.md for formulas and troubleshooting.

-- Explanation: Declare variables needed from the setup notebook.
DECLARE OR REPLACE VARIABLE raw_namespace STRING DEFAULT '`ftw-week-07`.`01-raw`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`05-data-quality`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Each UNION ALL branch returns the same check metric shape. This makes adding
-- a rule explicit and keeps every expectation visible in the persisted table.
INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  SELECT
    'courses' AS dataset_name,
    'code_module, code_presentation' AS column_name,
    'course business key is complete and unique' AS check_name,
    'COMPLETENESS' AS quality_dimension,
    'NULL_UNIQUE' AS check_type,
    'No null or duplicate course presentation keys' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'data_engineering' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(code_module IS NULL OR code_presentation IS NULL)
      + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)) AS failed_count
  FROM IDENTIFIER(raw_namespace || '.courses')

  UNION ALL

  SELECT
    'assessments', 'id_assessment', 'assessment key and values are valid',
    'VALIDITY', 'NULL_UNIQUE_RANGE', 'Unique key, accepted type, weight 0-100, and required due date',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL
      OR assessment_type NOT IN ('CMA', 'TMA', 'Exam')
      OR weight NOT BETWEEN 0 AND 100
      OR (assessment_type <> 'Exam' AND assessment_date IS NULL)
    ) + COUNT(*) - COUNT(DISTINCT id_assessment)
  FROM IDENTIFIER(raw_namespace || '.assessments')

  UNION ALL

  SELECT
    'vle', 'code_module, code_presentation, id_site', 'VLE activity key and window are valid',
    'VALIDITY', 'NULL_UNIQUE_RANGE', 'Unique activity key and an ordered optional week window',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_site IS NULL OR code_module IS NULL OR code_presentation IS NULL
      OR activity_type IS NULL OR TRIM(activity_type) = ''
      OR (week_from IS NOT NULL AND week_to IS NOT NULL AND week_from > week_to)
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_site))
  FROM IDENTIFIER(raw_namespace || '.vle')

  UNION ALL

  SELECT
    'student_info', 'code_module, code_presentation, id_student', 'student enrollment row is valid',
    'VALIDITY', 'NULL_UNIQUE_ACCEPTED_VALUES', 'Unique enrollment key and accepted demographic and outcome values',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_student IS NULL OR code_module IS NULL OR code_presentation IS NULL
      OR gender NOT IN ('F', 'M') OR disability NOT IN ('N', 'Y')
      OR final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
      OR age_band NOT IN ('0-35', '35-55', '55<=')
      OR region IS NULL OR TRIM(region) = ''
      OR highest_education IS NULL OR TRIM(highest_education) = ''
      OR num_of_prev_attempts < 0 OR studied_credits <= 0
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_info')

  UNION ALL

  SELECT
    'student_registration', 'code_module, code_presentation, id_student', 'registration row is valid',
    'CONSISTENCY', 'NULL_UNIQUE_BUSINESS_RULE', 'Unique enrollment key and unregistration is not before registration',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_student IS NULL OR code_module IS NULL OR code_presentation IS NULL
      OR (date_registration IS NOT NULL AND date_unregistration IS NOT NULL
        AND date_unregistration < date_registration)
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_registration')

  UNION ALL

  SELECT
    'student_assessment', 'id_assessment, id_student', 'assessment submission row is valid',
    'VALIDITY', 'NULL_UNIQUE_RANGE', 'Unique submission key, banked flag 0/1, and non-null scores 0-100',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL OR id_student IS NULL OR date_submitted IS NULL
      OR is_banked NOT IN (0, 1) OR score < 0 OR score > 100
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(id_assessment, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_assessment')

  UNION ALL

  SELECT
    'student_vle', 'code_module, code_presentation, id_student, id_site, activity_date',
    'VLE interaction required values are valid', 'VALIDITY', 'NULL_RANGE',
    'Required identifiers and date are present and click count is positive',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_student IS NULL OR id_site IS NULL OR code_module IS NULL OR code_presentation IS NULL
      OR activity_date IS NULL OR sum_click IS NULL OR sum_click <= 0
    )
  FROM IDENTIFIER(raw_namespace || '.student_vle')

  UNION ALL

  SELECT
    'bronze_all', '_rescued_data', 'all CSV fields match their explicit schemas',
    'VALIDITY', 'SCHEMA', 'No row contains rescued data after typed ingestion',
    0, 'WARNING', 'data_engineering', SUM(table_count), SUM(rescued_count)
  FROM (
    SELECT COUNT(*) AS table_count, COUNT_IF(_rescued_data IS NOT NULL) AS rescued_count
    FROM IDENTIFIER(raw_namespace || '.courses')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.assessments')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.vle')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.student_info')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.student_registration')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.student_assessment')
    UNION ALL SELECT COUNT(*), COUNT_IF(_rescued_data IS NOT NULL)
    FROM IDENTIFIER(raw_namespace || '.student_vle')
  ) AS rescued

  UNION ALL

  SELECT
    observed.dataset_name,
    'row_count',
    'source volume matches the published OULAD snapshot',
    'TIMELINESS_VOLUME',
    'VOLUME',
    CONCAT('Row count remains within 1 percent of baseline ', CAST(expected.expected_count AS STRING)),
    CAST(1.0 AS DECIMAL(7, 3)),
    'MEDIUM',
    'data_engineering',
    observed.observed_count,
    ABS(observed.observed_count - expected.expected_count)
  FROM (
    SELECT 'courses' AS dataset_name, COUNT(*) AS observed_count
    FROM IDENTIFIER(raw_namespace || '.courses')
    UNION ALL SELECT 'assessments', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.assessments')
    UNION ALL SELECT 'vle', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.vle')
    UNION ALL SELECT 'student_info', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_info')
    UNION ALL SELECT 'student_registration', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_registration')
    UNION ALL SELECT 'student_assessment', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_assessment')
    UNION ALL SELECT 'student_vle', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_vle')
  ) AS observed
  INNER JOIN (
    -- These are the approved counts for the attached OULAD homework snapshot.
    -- Update them only when the group intentionally adopts a different snapshot.
    SELECT * FROM VALUES
      ('courses', 22),
      ('assessments', 206),
      ('vle', 6364),
      ('student_info', 32593),
      ('student_registration', 32593),
      ('student_assessment', 173912),
      ('student_vle', 10655280)
    AS expected(dataset_name, expected_count)
  ) AS expected
    ON observed.dataset_name = expected.dataset_name
),
-- Convert raw issue counts to row-weighted scores. GREATEST protects the stored
-- passed count when overlapping predicates make failed_count exceed total_count.
scored AS (
  SELECT
    *,
    CAST(CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END AS DECIMAL(7, 3))
      AS failure_pct,
    CAST(CASE WHEN total_count = 0 THEN 0.0
      ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count END AS DECIMAL(7, 3))
      AS score_pct
  FROM checks
),
-- A zero-row required dataset fails. Otherwise the threshold determines FAIL;
-- a nonzero count inside tolerance becomes WARNING rather than PASS.
classified AS (
  SELECT
    *,
    CASE WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'
      WHEN failed_count > 0 THEN 'WARNING' ELSE 'PASS' END AS status
  FROM scored
)
SELECT
  dq_run_id,
  dq_executed_at,
  'BRONZE',
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
  GREATEST(total_count - failed_count, 0),
  score_pct,
  failure_pct,
  status
FROM classified;

-- Stop the pipeline only for current-run critical failures. Medium issues remain
-- queryable in the dashboard and do not erase the detailed results above.
SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Bronze data quality check failed; inspect 05-data-quality.dq_check_results'
  ) AS bronze_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'BRONZE'
ORDER BY dataset_name, check_name;
