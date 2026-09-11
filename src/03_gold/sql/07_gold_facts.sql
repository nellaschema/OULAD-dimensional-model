-- Databricks notebook source
-- Name: 07 - Gold Facts
-- Purpose: Build the two facts explicitly required by the OULAD assignment.
-- Grain: One assessment submission, or one student-presentation-site-relative-day interaction.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.fact_assessments')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', CAST(submission.id_assessment AS STRING), CAST(submission.id_student AS STRING)),
    256
  ) AS assessment_submission_key,
  SHA2(CAST(submission.id_student AS STRING), 256) AS student_key,
  SHA2(assessment.code_module, 256) AS course_key,
  SHA2(CONCAT_WS('||', assessment.code_module, assessment.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  SHA2(CAST(submission.date_submitted AS STRING), 256) AS submission_date_key,
  CASE
    WHEN assessment.assessment_date IS NULL THEN NULL
    ELSE SHA2(CAST(assessment.assessment_date AS STRING), 256)
  END AS due_date_key,
  CAST(submission.id_assessment AS BIGINT) AS id_assessment,
  assessment.assessment_type,
  CAST(assessment.weight AS DECIMAL(5, 2)) AS assessment_weight,
  CAST(submission.is_banked AS BOOLEAN) AS is_banked,
  CAST(submission.score AS DECIMAL(5, 2)) AS score
FROM IDENTIFIER(clean_namespace || '.student_assessment_clean') AS submission
INNER JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
  ON submission.id_assessment = assessment.id_assessment
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
  ON assessment.code_module = student.code_module
  AND assessment.code_presentation = student.code_presentation
  AND submission.id_student = student.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.fact_vle_interactions')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS(
      '||', interaction.code_module, interaction.code_presentation,
      CAST(interaction.id_student AS STRING), CAST(interaction.id_site AS STRING),
      CAST(interaction.activity_date AS STRING)
    ),
    256
  ) AS vle_interaction_key,
  SHA2(CAST(interaction.id_student AS STRING), 256) AS student_key,
  SHA2(interaction.code_module, 256) AS course_key,
  SHA2(CONCAT_WS('||', interaction.code_module, interaction.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  SHA2(CAST(interaction.activity_date AS STRING), 256) AS activity_date_id,
  CAST(interaction.id_site AS BIGINT) AS id_site,
  activity.activity_type,
  CAST(interaction.sum_click AS BIGINT) AS sum_click
FROM IDENTIFIER(clean_namespace || '.student_vle_clean') AS interaction
INNER JOIN IDENTIFIER(clean_namespace || '.vle_clean') AS activity
  ON interaction.code_module = activity.code_module
  AND interaction.code_presentation = activity.code_presentation
  AND interaction.id_site = activity.id_site
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
  ON interaction.code_module = student.code_module
  AND interaction.code_presentation = student.code_presentation
  AND interaction.id_student = student.id_student;
