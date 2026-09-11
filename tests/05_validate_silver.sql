-- Databricks notebook source
-- Name: 05 - Silver Validation
-- Purpose: Persist clean-layer DQ results and stop on broken keys or relationships.
-- Grain: One row per data quality check and pipeline run.

-- Explanation: Declare variables needed from the setup notebook.
DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`01-raw`';
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Keep checks in one compatible UNION ALL set so scores and status rules are
-- calculated consistently across every Silver dataset.
INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  SELECT
    'courses_clean' AS dataset_name, 'code_module, code_presentation' AS column_name,
    'course grain is unique' AS check_name, 'UNIQUENESS' AS quality_dimension,
    'UNIQUE' AS check_type, 'One row per module and presentation' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct, 'CRITICAL' AS severity,
    'data_engineering' AS check_owner, COUNT(*) AS total_count,
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)) AS failed_count
  FROM IDENTIFIER(clean_namespace || '.courses_clean')

  UNION ALL

  SELECT
    'assessments_clean', 'code_module, code_presentation', 'all assessments match a course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY', 'Every assessment has a matching clean course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*), COUNT_IF(course.code_module IS NULL)
  FROM IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course
    ON assessment.code_module = course.code_module
    AND assessment.code_presentation = course.code_presentation

  UNION ALL

  SELECT
    'student_info_clean', 'code_module, code_presentation, id_student', 'student enrollment grain is unique',
    'UNIQUENESS', 'UNIQUE', 'One row per student and module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')

  UNION ALL

  SELECT
    'student_registration_clean', 'code_module, code_presentation, id_student',
    'all registration rows match a student enrollment', 'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY',
    'Every registration has a matching clean student enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*), COUNT_IF(student.id_student IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_registration_clean') AS registration
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON registration.code_module = student.code_module
    AND registration.code_presentation = student.code_presentation
    AND registration.id_student = student.id_student

  UNION ALL

  SELECT
    'student_assessment_clean', 'id_assessment, id_student',
    'submission grain and relationships are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One row per student-assessment and every submission matches assessment and enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(assessment.id_assessment IS NULL OR student.id_student IS NULL)
      + COUNT(*) - COUNT(DISTINCT STRUCT(submission.id_assessment, submission.id_student))
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean') AS submission
  LEFT JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
    ON submission.id_assessment = assessment.id_assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON assessment.code_module = student.code_module
    AND assessment.code_presentation = student.code_presentation
    AND submission.id_student = student.id_student

  UNION ALL

  SELECT
    'student_vle_clean', 'code_module, code_presentation, id_student, id_site, activity_date',
    'daily VLE grain and relationships are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One positive row per student, site, and relative day with matching activity and enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(activity.id_site IS NULL OR student.id_student IS NULL OR interaction.sum_click <= 0)
      + COUNT(*) - COUNT(DISTINCT STRUCT(
        interaction.code_module, interaction.code_presentation, interaction.id_student,
        interaction.id_site, interaction.activity_date
      ))
  FROM IDENTIFIER(clean_namespace || '.student_vle_clean') AS interaction
  LEFT JOIN IDENTIFIER(clean_namespace || '.vle_clean') AS activity
    ON interaction.code_module = activity.code_module
    AND interaction.code_presentation = activity.code_presentation
    AND interaction.id_site = activity.id_site
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
    ON interaction.code_module = student.code_module
    AND interaction.code_presentation = student.code_presentation
    AND interaction.id_student = student.id_student

  UNION ALL

  SELECT
    'student_assessment_clean', 'score', 'score null rate is monitored',
    'COMPLETENESS', 'NULL_RATE', 'Missing scores remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)), 'MEDIUM', 'analytics', COUNT(*), COUNT_IF(score IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
),
-- Row-weighted score calculation shared by every check in this suite.
scored AS (
  SELECT
    *,
    CAST(CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END AS DECIMAL(7, 3))
      AS failure_pct,
    CAST(CASE WHEN total_count = 0 THEN 0.0
      ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count END AS DECIMAL(7, 3)) AS score_pct
  FROM checks
),
-- Zero-row required outputs fail; tolerated nonzero defects become warnings.
classified AS (
  SELECT
    *,
    CASE WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'
      WHEN failed_count > 0 THEN 'WARNING' ELSE 'PASS' END AS status
  FROM scored
)
SELECT
  dq_run_id, dq_executed_at, 'SILVER', dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity, check_owner,
  total_count, failed_count, GREATEST(total_count - failed_count, 0), score_pct, failure_pct, status
FROM classified;

-- Prevent Gold from running when a current Silver critical rule failed.
SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,
    'critical Silver data quality check failed; inspect 05-data-quality.dq_check_results'
  ) AS silver_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'SILVER'
ORDER BY dataset_name, check_name;