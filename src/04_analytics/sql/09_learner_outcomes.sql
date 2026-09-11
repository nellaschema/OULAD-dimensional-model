-- Databricks notebook source
-- Name: 09 - Learner Outcomes
-- Purpose: Publish the supporting cohort model and outcome summary.
-- Grain: student_cohort is one student per module presentation; learner_outcomes is one presentation.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';

-- Supporting reporting model only. It is intentionally not a third core Gold fact.
CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.student_cohort')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', student.code_module, student.code_presentation, CAST(student.id_student AS STRING)),
    256
  ) AS student_cohort_key,
  SHA2(CAST(student.id_student AS STRING), 256) AS student_key,
  SHA2(student.code_module, 256) AS course_key,
  SHA2(CONCAT_WS('||', student.code_module, student.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  student.code_module,
  student.code_presentation,
  student.id_student,
  registration.date_registration,
  registration.date_unregistration,
  student.num_of_prev_attempts,
  student.studied_credits,
  student.final_result,
  CAST(student.final_result = 'Withdrawn' AS BOOLEAN) AS is_withdrawn,
  CASE WHEN student.final_result = 'Withdrawn' THEN 1 ELSE 0 END AS withdrawn_count,
  CASE WHEN student.final_result = 'Fail' THEN 1 ELSE 0 END AS failed_count,
  CASE WHEN student.final_result = 'Pass' THEN 1 ELSE 0 END AS passed_count,
  CASE WHEN student.final_result = 'Distinction' THEN 1 ELSE 0 END AS distinction_count,
  1 AS enrollment_count
FROM IDENTIFIER(clean_namespace || '.student_info_clean') AS student
LEFT JOIN IDENTIFIER(clean_namespace || '.student_registration_clean') AS registration
  ON student.code_module = registration.code_module
  AND student.code_presentation = registration.code_presentation
  AND student.id_student = registration.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.learner_outcomes')
USING DELTA
AS
SELECT
  module_presentation_key,
  course_key,
  code_module,
  code_presentation,
  COUNT(*) AS enrolled_students,
  SUM(withdrawn_count) AS withdrawn_students,
  SUM(failed_count) AS failed_students,
  SUM(passed_count) AS passed_students,
  SUM(distinction_count) AS distinction_students,
  AVG(CASE WHEN final_result IN ('Pass', 'Distinction') THEN 1.0 ELSE 0.0 END)
    AS successful_outcome_rate,
  AVG(CASE WHEN final_result = 'Withdrawn' THEN 1.0 ELSE 0.0 END) AS withdrawal_rate,
  AVG(studied_credits) AS average_studied_credits,
  AVG(num_of_prev_attempts) AS average_previous_attempts
FROM IDENTIFIER(analytics_namespace || '.student_cohort')
GROUP BY module_presentation_key, course_key, code_module, code_presentation;
