-- Databricks notebook source
-- Databricks notebook source
-- Name: 05 - Silver Validation
-- Purpose: Validate every clean table, preserve known source limitations as
-- warnings, reconcile Bronze with Silver, and block Gold on critical failures.
-- Grain: One row per data-quality check and validation run.
-- Depends on: Passing Bronze validation and all seven Silver *_clean tables.
-- Produces: SILVER rows in 05-data-quality.dq_check_results.

DECLARE OR REPLACE VARIABLE raw_namespace STRING
  DEFAULT '`ftw-week-07`.`01-raw`';
DECLARE OR REPLACE VARIABLE clean_namespace STRING
  DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING
  DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Ensure the DQ table exists before inserting results
-- Using 04-analytics schema because 05-data-quality requires CREATE SCHEMA permission
CREATE TABLE IF NOT EXISTS IDENTIFIER(dq_namespace || '.dq_check_results') (
  run_id STRING NOT NULL,
  executed_at TIMESTAMP NOT NULL,
  layer STRING NOT NULL,
  dataset_name STRING NOT NULL,
  column_name STRING,
  check_name STRING NOT NULL,
  quality_dimension STRING NOT NULL,
  check_type STRING NOT NULL,
  expectation STRING NOT NULL,
  threshold_pct DECIMAL(7, 3) NOT NULL,
  severity STRING NOT NULL,
  check_owner STRING NOT NULL,
  total_count BIGINT NOT NULL,
  failed_count BIGINT NOT NULL,
  passed_count BIGINT NOT NULL,
  score_pct DECIMAL(7, 3) NOT NULL,
  failure_pct DECIMAL(7, 3) NOT NULL,
  status STRING NOT NULL
)
USING DELTA;

-- Validation remains read-only against Silver. Primary and foreign-key metadata
-- should be registered separately after the data passes its checks.
INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  -- COURSES ---------------------------------------------------------------
  SELECT
    'courses_clean' AS dataset_name,
    'code_module, code_presentation, module_presentation_length' AS column_name,
    'clean course values and grain are valid' AS check_name,
    'VALIDITY' AS quality_dimension,
    'NULL_RANGE_UNIQUE' AS check_type,
    'One valid row per module and presentation' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'data_engineering' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(
      code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR module_presentation_length IS NULL
      OR module_presentation_length <= 0
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation))
      AS failed_count
  FROM IDENTIFIER(clean_namespace || '.courses_clean')

  -- ASSESSMENTS -----------------------------------------------------------
  UNION ALL

  SELECT
    'assessments_clean',
    'id_assessment, code_module, code_presentation, assessment_type, assessment_date, weight',
    'clean assessment values and grain are valid',
    'VALIDITY', 'NULL_ACCEPTED_VALUES_RANGE_UNIQUE',
    'One valid row per assessment; non-Exam assessments have a due date',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR assessment_type IS NULL
      OR assessment_type NOT IN ('CMA', 'TMA', 'Exam')
      OR weight IS NULL OR weight NOT BETWEEN 0 AND 100
      OR (assessment_type <> 'Exam' AND assessment_date IS NULL)
    ) + COUNT(*) - COUNT(DISTINCT id_assessment)
  FROM IDENTIFIER(clean_namespace || '.assessments_clean')

  UNION ALL

  SELECT
    'assessments_clean', 'code_module, code_presentation',
    'every clean assessment matches a clean course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every clean assessment has a matching clean course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course
    ON assessment.code_module = course.code_module
    AND assessment.code_presentation = course.code_presentation

  -- VLE RESOURCES ---------------------------------------------------------
  UNION ALL

  SELECT
    'vle_clean',
    'id_site, code_module, code_presentation, activity_type, week_from, week_to',
    'clean VLE values and grain are valid',
    'VALIDITY', 'NULL_RANGE_PAIR_UNIQUE',
    'One valid VLE resource per site and presentation; optional week bounds are paired and ordered',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_site IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR activity_type IS NULL OR TRIM(activity_type) = ''
      OR (week_from IS NULL AND week_to IS NOT NULL)
      OR (week_from IS NOT NULL AND week_to IS NULL)
      OR (week_from IS NOT NULL AND week_to IS NOT NULL AND week_from > week_to)
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_site))
  FROM IDENTIFIER(clean_namespace || '.vle_clean')

  UNION ALL

  SELECT
    'vle_clean', 'code_module, code_presentation',
    'every clean VLE resource matches a clean course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every clean VLE resource has a matching clean course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(clean_namespace || '.vle_clean') AS vle
  LEFT JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course
    ON vle.code_module = course.code_module
    AND vle.code_presentation = course.code_presentation

  -- STUDENT INFORMATION --------------------------------------------------
  UNION ALL

  SELECT
    'student_info_clean',
    'student enrollment and required demographic fields',
    'clean student enrollment values and grain are valid',
    'VALIDITY', 'NULL_ACCEPTED_VALUES_RANGE_UNIQUE',
    'One valid enrollment row per student and module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR gender IS NULL OR gender NOT IN ('F', 'M')
      OR region IS NULL OR TRIM(region) = ''
      OR highest_education IS NULL OR TRIM(highest_education) = ''
      OR age_band IS NULL OR age_band NOT IN ('0-35', '35-55', '55<=')
      OR disability IS NULL OR disability NOT IN ('N', 'Y')
      OR final_result IS NULL
      OR final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
      OR num_of_prev_attempts IS NULL OR num_of_prev_attempts < 0
      OR studied_credits IS NULL OR studied_credits <= 0
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')

  UNION ALL

  SELECT
    'student_info_clean', 'imd_band',
    'non-null clean IMD bands use an accepted value',
    'VALIDITY', 'ACCEPTED_VALUES_WHEN_PRESENT',
    'Known IMD bands are accepted; missing values are monitored separately',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      imd_band IS NOT NULL
      AND imd_band NOT IN (
        '0-10%', '10-20', '10-20%', '20-30%', '30-40%', '40-50%',
        '50-60%', '60-70%', '70-80%', '80-90%', '90-100%'
      )
    )
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')

  UNION ALL

  SELECT
    'student_info_clean', 'code_module, code_presentation',
    'every clean student enrollment matches a clean course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every clean student enrollment has a matching clean course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_info_clean') AS student
  LEFT JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course
    ON student.code_module = course.code_module
    AND student.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'student_info_clean', 'imd_band', 'clean IMD-band null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing IMD bands remain at or below 5 percent',
    CAST(5.0 AS DECIMAL(7, 3)), 'MEDIUM', 'analytics', COUNT(*),
    COUNT_IF(imd_band IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')

  -- STUDENT REGISTRATION -------------------------------------------------
  UNION ALL

  SELECT
    'student_registration_clean',
    'code_module, code_presentation, id_student, date_registration, date_unregistration',
    'clean registration keys, date order, and grain are valid',
    'CONSISTENCY', 'NULL_BUSINESS_RULE_UNIQUE',
    'One registration per enrollment; unregistration is not before registration when both dates exist',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR (
        date_registration IS NOT NULL
        AND date_unregistration IS NOT NULL
        AND date_unregistration < date_registration
      )
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(clean_namespace || '.student_registration_clean')

  UNION ALL

  SELECT
    'student_registration_clean', 'code_module, code_presentation, id_student',
    'every clean registration matches a clean student enrollment',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every clean registration has a matching clean student enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(student.id_student IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_registration_clean') AS registration
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON registration.code_module = student.code_module
    AND registration.code_presentation = student.code_presentation
    AND registration.id_student = student.id_student

  UNION ALL

  SELECT
    'student_registration_clean', 'date_registration',
    'clean registration-date null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing registration dates remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)), 'MEDIUM', 'data_engineering', COUNT(*),
    COUNT_IF(date_registration IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_registration_clean')

  -- STUDENT ASSESSMENT ---------------------------------------------------
  UNION ALL

  SELECT
    'student_assessment_clean',
    'id_assessment, id_student, date_submitted, is_banked, score',
    'clean assessment-submission values and grain are valid',
    'VALIDITY', 'NULL_RANGE_UNIQUE',
    'One valid submission per student and assessment; score is 0-100 when present',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL OR id_student IS NULL OR date_submitted IS NULL
      OR is_banked IS NULL
      OR (score IS NOT NULL AND score NOT BETWEEN 0 AND 100)
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(id_assessment, id_student))
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')

  UNION ALL

  SELECT
    'student_assessment_clean', 'id_assessment, id_student',
    'every clean submission matches an assessment and student enrollment',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every clean submission resolves to an assessment and its student enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(assessment.id_assessment IS NULL OR student.id_student IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean') AS submission
  LEFT JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
    ON submission.id_assessment = assessment.id_assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON assessment.code_module = student.code_module
    AND assessment.code_presentation = student.code_presentation
    AND submission.id_student = student.id_student

  UNION ALL

  SELECT
    'student_assessment_clean', 'score',
    'clean assessment-score null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing assessment scores remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)), 'MEDIUM', 'analytics', COUNT(*),
    COUNT_IF(score IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')

  -- STUDENT VLE ----------------------------------------------------------
  UNION ALL

  SELECT
    'student_vle_clean',
    'code_module, code_presentation, id_student, id_site, activity_date, sum_click',
    'clean daily VLE values, relationships, and grain are valid',
    'REFERENTIAL_INTEGRITY', 'NULL_RANGE_UNIQUE_FOREIGN_KEY',
    'One positive daily row per student and site with matching enrollment and VLE resource',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      interaction.code_module IS NULL OR TRIM(interaction.code_module) = ''
      OR interaction.code_presentation IS NULL OR TRIM(interaction.code_presentation) = ''
      OR interaction.id_student IS NULL OR interaction.id_site IS NULL
      OR interaction.activity_date IS NULL
      OR interaction.sum_click IS NULL OR interaction.sum_click <= 0
      OR student.id_student IS NULL OR activity.id_site IS NULL
    ) + COUNT(*) - COUNT(DISTINCT STRUCT(
      interaction.code_module,
      interaction.code_presentation,
      interaction.id_student,
      interaction.id_site,
      interaction.activity_date
    ))
  FROM IDENTIFIER(clean_namespace || '.student_vle_clean') AS interaction
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON interaction.code_module = student.code_module
    AND interaction.code_presentation = student.code_presentation
    AND interaction.id_student = student.id_student
  LEFT JOIN IDENTIFIER(clean_namespace || '.vle_clean') AS activity
    ON interaction.code_module = activity.code_module
    AND interaction.code_presentation = activity.code_presentation
    AND interaction.id_site = activity.id_site

  -- BRONZE-TO-SILVER ROW RECONCILIATION ---------------------------------
  UNION ALL

  SELECT
    clean_counts.dataset_name,
    'row_count',
    'Bronze and Silver row counts reconcile',
    'ACCURACY',
    'VOLUME_RECONCILIATION',
    'Cleaning preserves every validated non-aggregated source row',
    0,
    'CRITICAL',
    'data_engineering',
    raw_counts.row_count,
    ABS(raw_counts.row_count - clean_counts.row_count)
  FROM (
    SELECT 'courses_clean' AS dataset_name, COUNT(*) AS row_count
    FROM IDENTIFIER(raw_namespace || '.courses')
    UNION ALL SELECT 'assessments_clean', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.assessments')
    UNION ALL SELECT 'vle_clean', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.vle')
    UNION ALL SELECT 'student_info_clean', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_info')
    UNION ALL SELECT 'student_registration_clean', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_registration')
    UNION ALL SELECT 'student_assessment_clean', COUNT(*)
    FROM IDENTIFIER(raw_namespace || '.student_assessment')
  ) AS raw_counts
  INNER JOIN (
    SELECT 'courses_clean' AS dataset_name, COUNT(*) AS row_count
    FROM IDENTIFIER(clean_namespace || '.courses_clean')
    UNION ALL SELECT 'assessments_clean', COUNT(*)
    FROM IDENTIFIER(clean_namespace || '.assessments_clean')
    UNION ALL SELECT 'vle_clean', COUNT(*)
    FROM IDENTIFIER(clean_namespace || '.vle_clean')
    UNION ALL SELECT 'student_info_clean', COUNT(*)
    FROM IDENTIFIER(clean_namespace || '.student_info_clean')
    UNION ALL SELECT 'student_registration_clean', COUNT(*)
    FROM IDENTIFIER(clean_namespace || '.student_registration_clean')
    UNION ALL SELECT 'student_assessment_clean', COUNT(*)
    FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
  ) AS clean_counts
    ON raw_counts.dataset_name = clean_counts.dataset_name

  -- student_vle changes grain in Silver, so compare the expected daily group
  -- count and the additive click total instead of requiring equal row counts.
  UNION ALL

  SELECT
    'student_vle_clean',
    'daily-grain row_count, sum_click',
    'Bronze VLE interactions reconcile with daily Silver aggregation',
    'ACCURACY',
    'GRAIN_CONTROL_TOTAL_RECONCILIATION',
    'Silver row count equals the raw distinct daily grain and total clicks are unchanged',
    0,
    'CRITICAL',
    'data_engineering',
    2,
    CASE WHEN raw_controls.daily_row_count <> clean_controls.daily_row_count THEN 1 ELSE 0 END
      + CASE WHEN raw_controls.click_sum <> clean_controls.click_sum THEN 1 ELSE 0 END
  FROM (
    SELECT
      COUNT(DISTINCT STRUCT(
        UPPER(TRIM(code_module)),
        UPPER(TRIM(code_presentation)),
        id_student,
        id_site,
        activity_date
      )) AS daily_row_count,
      SUM(sum_click) AS click_sum
    FROM IDENTIFIER(raw_namespace || '.student_vle')
  ) AS raw_controls
  CROSS JOIN (
    SELECT COUNT(*) AS daily_row_count, SUM(sum_click) AS click_sum
    FROM IDENTIFIER(clean_namespace || '.student_vle_clean')
  ) AS clean_controls
),
scored AS (
  SELECT
    *,
    CAST(
      CASE
        WHEN total_count = 0 THEN 100.0
        ELSE 100.0 * failed_count / total_count
      END AS DECIMAL(7, 3)
    ) AS failure_pct,
    CAST(
      CASE
        WHEN total_count = 0 THEN 0.0
        ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count
      END AS DECIMAL(7, 3)
    ) AS score_pct
  FROM checks
),
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
  dq_run_id,
  dq_executed_at,
  'SILVER',
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

-- The detailed rows are saved before this gate. A critical failure stops Gold
-- while leaving the Silver issue available to the DQ dashboard.
SELECT
  dataset_name,
  check_name,
  status,
  severity,
  failed_count,
  total_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Silver data-quality check failed; inspect 04-analytics.dq_check_results'
  ) AS silver_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'SILVER'
ORDER BY
  CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
  dataset_name,
  check_name;
