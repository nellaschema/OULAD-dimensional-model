-- Databricks notebook source
-- Databricks notebook source
-- Name: 03 - Bronze Validation
-- Purpose: Validate the seven typed Bronze tables, save detailed DQ results,
-- and stop the pipeline when a critical source-contract rule fails.
-- Grain: One row per data-quality check and validation run.
-- Depends on: src/00_setup/01_setup.sql and the seven Bronze tables.
-- Produces: BRONZE rows in 05-data-quality.dq_check_results.

DECLARE OR REPLACE VARIABLE raw_namespace STRING
  DEFAULT '`ftw-week-07`.`01-raw`';
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

-- dq_check_results is created by src/00_setup/01_setup.sql. Keeping it in the
-- dedicated DQ schema allows the final DQ views and Metabase queries to read
-- Bronze, Silver, Gold, and Analytics results from one location.
INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  -- COURSES ---------------------------------------------------------------
  SELECT
    'courses' AS dataset_name,
    'code_module, code_presentation, module_presentation_length' AS column_name,
    'required course values are valid' AS check_name,
    'VALIDITY' AS quality_dimension,
    'NULL_RANGE' AS check_type,
    'Course keys are populated and presentation length is positive' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,
    'CRITICAL' AS severity,
    'data_engineering' AS check_owner,
    COUNT(*) AS total_count,
    COUNT_IF(
      code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR module_presentation_length IS NULL
      OR module_presentation_length <= 0
    ) AS failed_count
  FROM IDENTIFIER(raw_namespace || '.courses')

  UNION ALL

  SELECT
    'courses', 'code_module, code_presentation',
    'course presentation grain is unique', 'UNIQUENESS', 'UNIQUE',
    'One row per module and presentation', 0, 'CRITICAL', 'data_engineering',
    COUNT(*), COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation))
  FROM IDENTIFIER(raw_namespace || '.courses')

  -- ASSESSMENTS -----------------------------------------------------------
  UNION ALL

  SELECT
    'assessments',
    'id_assessment, code_module, code_presentation, assessment_type, assessment_date, weight',
    'required assessment values are valid', 'VALIDITY', 'NULL_ACCEPTED_VALUES_RANGE',
    'Required keys, accepted type, weight 0-100, and a due date for non-Exam assessments',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR assessment_type IS NULL
      OR assessment_type NOT IN ('CMA', 'TMA', 'Exam')
      OR weight IS NULL OR weight NOT BETWEEN 0 AND 100
      OR (assessment_type <> 'Exam' AND assessment_date IS NULL)
    )
  FROM IDENTIFIER(raw_namespace || '.assessments')

  UNION ALL

  SELECT
    'assessments', 'id_assessment', 'assessment ID is unique',
    'UNIQUENESS', 'UNIQUE', 'One row per assessment ID',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT id_assessment)
  FROM IDENTIFIER(raw_namespace || '.assessments')

  UNION ALL

  SELECT
    'assessments', 'code_module, code_presentation',
    'every assessment matches a course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every assessment has a matching Bronze course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(raw_namespace || '.assessments') AS assessment
  LEFT JOIN IDENTIFIER(raw_namespace || '.courses') AS course
    ON assessment.code_module = course.code_module
    AND assessment.code_presentation = course.code_presentation

  -- VLE RESOURCES ---------------------------------------------------------
  UNION ALL

  SELECT
    'vle',
    'id_site, code_module, code_presentation, activity_type, week_from, week_to',
    'required VLE values and optional week window are valid',
    'VALIDITY', 'NULL_RANGE_PAIR',
    'Required keys and activity type; week bounds are both absent or both present and ordered',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_site IS NULL
      OR code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR activity_type IS NULL OR TRIM(activity_type) = ''
      OR (week_from IS NULL AND week_to IS NOT NULL)
      OR (week_from IS NOT NULL AND week_to IS NULL)
      OR (week_from IS NOT NULL AND week_to IS NOT NULL AND week_from > week_to)
    )
  FROM IDENTIFIER(raw_namespace || '.vle')

  UNION ALL

  SELECT
    'vle', 'code_module, code_presentation, id_site',
    'VLE resource grain is unique', 'UNIQUENESS', 'UNIQUE',
    'One row per VLE site in a module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_site))
  FROM IDENTIFIER(raw_namespace || '.vle')

  UNION ALL

  SELECT
    'vle', 'code_module, code_presentation',
    'every VLE resource matches a course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every VLE resource has a matching Bronze course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(raw_namespace || '.vle') AS vle
  LEFT JOIN IDENTIFIER(raw_namespace || '.courses') AS course
    ON vle.code_module = course.code_module
    AND vle.code_presentation = course.code_presentation

  -- STUDENT INFORMATION --------------------------------------------------
  UNION ALL

  SELECT
    'student_info',
    'student enrollment and required demographic fields',
    'required student enrollment values are valid',
    'VALIDITY', 'NULL_ACCEPTED_VALUES_RANGE',
    'Required enrollment, demographic, outcome, attempt, and credit values are valid',
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
    )
  FROM IDENTIFIER(raw_namespace || '.student_info')

  UNION ALL

  SELECT
    'student_info', 'imd_band', 'non-null IMD bands use an accepted source value',
    'VALIDITY', 'ACCEPTED_VALUES_WHEN_PRESENT',
    'Known IMD bands are accepted; a missing IMD band is monitored separately',
    0, 'CRITICAL', 'analytics', COUNT(*),
    COUNT_IF(
      imd_band IS NOT NULL
      AND imd_band NOT IN (
        '0-10%', '10-20', '10-20%', '20-30%', '30-40%', '40-50%',
        '50-60%', '60-70%', '70-80%', '80-90%', '90-100%'
      )
    )
  FROM IDENTIFIER(raw_namespace || '.student_info')

  UNION ALL

  SELECT
    'student_info', 'code_module, code_presentation, id_student',
    'student enrollment grain is unique', 'UNIQUENESS', 'UNIQUE',
    'One row per student and module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_info')

  UNION ALL

  SELECT
    'student_info', 'code_module, code_presentation',
    'every student enrollment matches a course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every student enrollment has a matching Bronze course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_info') AS student
  LEFT JOIN IDENTIFIER(raw_namespace || '.courses') AS course
    ON student.code_module = course.code_module
    AND student.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'student_info', 'imd_band', 'IMD-band null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing IMD bands remain at or below 5 percent',
    CAST(5.0 AS DECIMAL(7, 3)), 'MEDIUM', 'analytics', COUNT(*),
    COUNT_IF(imd_band IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_info')

  -- STUDENT REGISTRATION -------------------------------------------------
  UNION ALL

  SELECT
    'student_registration',
    'code_module, code_presentation, id_student, date_registration, date_unregistration',
    'registration keys and date order are valid',
    'CONSISTENCY', 'NULL_BUSINESS_RULE',
    'Required keys are present and unregistration is not before registration when both dates exist',
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
    )
  FROM IDENTIFIER(raw_namespace || '.student_registration')

  UNION ALL

  SELECT
    'student_registration', 'code_module, code_presentation, id_student',
    'registration grain is unique', 'UNIQUENESS', 'UNIQUE',
    'One registration row per student and module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_registration')

  UNION ALL

  SELECT
    'student_registration', 'code_module, code_presentation, id_student',
    'every registration matches a student enrollment',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every registration has a matching Bronze student enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(student.id_student IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_registration') AS registration
  LEFT JOIN IDENTIFIER(raw_namespace || '.student_info') AS student
    ON registration.code_module = student.code_module
    AND registration.code_presentation = student.code_presentation
    AND registration.id_student = student.id_student

  UNION ALL

  SELECT
    'student_registration', 'date_registration',
    'registration-date null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing registration dates remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)), 'MEDIUM', 'data_engineering', COUNT(*),
    COUNT_IF(date_registration IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_registration')

  -- STUDENT ASSESSMENT ---------------------------------------------------
  UNION ALL

  SELECT
    'student_assessment',
    'id_assessment, id_student, date_submitted, is_banked, score',
    'required assessment-submission values are valid',
    'VALIDITY', 'NULL_ACCEPTED_VALUES_RANGE',
    'Required keys and date, banked flag 0/1, and score 0-100 when present',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      id_assessment IS NULL OR id_student IS NULL OR date_submitted IS NULL
      OR is_banked IS NULL OR is_banked NOT IN (0, 1)
      OR (score IS NOT NULL AND score NOT BETWEEN 0 AND 100)
    )
  FROM IDENTIFIER(raw_namespace || '.student_assessment')

  UNION ALL

  SELECT
    'student_assessment', 'id_assessment, id_student',
    'student-assessment grain is unique', 'UNIQUENESS', 'UNIQUE',
    'One submission row per student and assessment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(id_assessment, id_student))
  FROM IDENTIFIER(raw_namespace || '.student_assessment')

  UNION ALL

  SELECT
    'student_assessment', 'id_assessment, id_student',
    'every submission matches an assessment and student enrollment',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every submission resolves to an assessment and its student enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(assessment.id_assessment IS NULL OR student.id_student IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_assessment') AS submission
  LEFT JOIN IDENTIFIER(raw_namespace || '.assessments') AS assessment
    ON submission.id_assessment = assessment.id_assessment
  LEFT JOIN IDENTIFIER(raw_namespace || '.student_info') AS student
    ON assessment.code_module = student.code_module
    AND assessment.code_presentation = student.code_presentation
    AND submission.id_student = student.id_student

  UNION ALL

  SELECT
    'student_assessment', 'score', 'assessment-score null rate is monitored',
    'COMPLETENESS', 'NULL_RATE',
    'Missing assessment scores remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)), 'MEDIUM', 'analytics', COUNT(*),
    COUNT_IF(score IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_assessment')

  -- STUDENT VLE ----------------------------------------------------------
  UNION ALL

  SELECT
    'student_vle',
    'code_module, code_presentation, id_student, id_site, activity_date, sum_click',
    'required student VLE values are valid',
    'VALIDITY', 'NULL_RANGE',
    'Required keys and date are present and click count is positive',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(
      code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR id_student IS NULL OR id_site IS NULL OR activity_date IS NULL
      OR sum_click IS NULL OR sum_click <= 0
    )
  FROM IDENTIFIER(raw_namespace || '.student_vle')

  UNION ALL

  SELECT
    'student_vle',
    'code_module, code_presentation, id_student, id_site',
    'every VLE interaction matches a student and VLE resource',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every raw VLE interaction resolves to its student enrollment and VLE resource',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(student.id_student IS NULL OR activity.id_site IS NULL)
  FROM IDENTIFIER(raw_namespace || '.student_vle') AS interaction
  LEFT JOIN IDENTIFIER(raw_namespace || '.student_info') AS student
    ON interaction.code_module = student.code_module
    AND interaction.code_presentation = student.code_presentation
    AND interaction.id_student = student.id_student
  LEFT JOIN IDENTIFIER(raw_namespace || '.vle') AS activity
    ON interaction.code_module = activity.code_module
    AND interaction.code_presentation = activity.code_presentation
    AND interaction.id_site = activity.id_site

  -- SCHEMA CONFORMANCE ---------------------------------------------------
  UNION ALL

  SELECT
    'bronze_all', '_rescued_data',
    'all CSV fields match their explicit ingestion schemas',
    'VALIDITY', 'SCHEMA',
    'No Bronze row contains rescued data after typed ingestion',
    0, 'CRITICAL', 'data_engineering', SUM(table_count), SUM(rescued_count)
  FROM (
    SELECT COUNT(*) AS table_count,
      COUNT_IF(_rescued_data IS NOT NULL) AS rescued_count
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

  -- SOURCE VOLUME --------------------------------------------------------
  UNION ALL

  SELECT
    observed.dataset_name,
    'row_count',
    'source volume matches the approved OULAD snapshot',
    'TIMELINESS_VOLUME',
    'VOLUME',
    CONCAT(
      'Observed row count remains within 1 percent of baseline ',
      CAST(expected.expected_count AS STRING)
    ),
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

-- The detailed rows are saved before this gate. A critical failure stops
-- Silver while leaving the issue available to the DQ dashboard.
SELECT
  dataset_name,
  check_name,
  status,
  severity,
  failed_count,
  total_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Bronze data-quality check failed; inspect 05-data-quality.dq_check_results'
  ) AS bronze_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'BRONZE'
ORDER BY
  CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
  dataset_name,
  check_name;
