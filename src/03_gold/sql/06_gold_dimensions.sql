-- Databricks notebook source
-- DBTITLE 1,Cell 1
-- Name: 06 - Gold Dimensions
-- Purpose: Build the five conformed dimensions required by the OULAD assignment.
-- Grain: One row per student, course, module presentation, relative day, or demographic profile.
-- Depends on: Passing Silver validation and, for migration runs, Gold reset.
-- Produces: dim_student, dim_course, dim_module_presentation, dim_demographics,
-- dim_date, plus three role-playing date views.
-- Why: Shared dimensions let both facts use consistent keys and descriptions.
-- Rerun behavior: Tables and role-playing views are fully replaced.
-- Key method: SHA-256 of stable business-key fields gives deterministic joins
-- across the SQL compatibility build, dbt models, and Analytics tables.
-- Documentation: See src/README.md and docs/data-model.md.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

-- dim_student contains stable anonymized identity only. DISTINCT is required
-- because one student may appear in several module presentations.
CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_student')
USING DELTA
AS
SELECT DISTINCT
  SHA2(CAST(id_student AS STRING), 256) AS student_key,
  id_student
FROM IDENTIFIER(clean_namespace || '.student_info_clean');

-- dim_course represents a module independent of when it was offered.
CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_course')
USING DELTA
AS
SELECT DISTINCT
  SHA2(code_module, 256) AS course_key,
  code_module
FROM IDENTIFIER(clean_namespace || '.courses_clean');

-- dim_module_presentation represents a specific run such as AAA-2013J. Course
-- and presentation are separate dimensions because they have different grains;
-- length and derived year/term belong to the presentation.
CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_module_presentation')
USING DELTA
AS
SELECT
  SHA2(CONCAT_WS('||', code_module, code_presentation), 256)
    AS module_presentation_key,
  SHA2(code_module, 256) AS course_key,
  code_module,
  code_presentation,
  CAST(SUBSTRING(code_presentation, 1, 4) AS INT) AS presentation_year,
  SUBSTRING(code_presentation, 5, 1) AS presentation_term,
  CASE SUBSTRING(code_presentation, 5, 1)
    WHEN 'B' THEN 'February start'
    WHEN 'J' THEN 'October start'
    ELSE 'Other start'
  END AS presentation_term_name,
  module_presentation_length
FROM IDENTIFIER(clean_namespace || '.courses_clean');

-- dim_demographics represents a distinct profile, not a student history table.
-- UNKNOWN participates only in key construction so null attributes hash
-- consistently; the displayed source attributes remain null. Enrollment outcome
-- is deliberately excluded because it is not a demographic characteristic.
CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_demographics')
USING DELTA
AS
SELECT DISTINCT
  SHA2(
    CONCAT_WS(
      '||',
      COALESCE(gender, 'UNKNOWN'),
      COALESCE(region, 'UNKNOWN'),
      COALESCE(highest_education, 'UNKNOWN'),
      COALESCE(imd_band, 'UNKNOWN'),
      COALESCE(age_band, 'UNKNOWN'),
      COALESCE(disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability
FROM IDENTIFIER(clean_namespace || '.student_info_clean');

-- dim_date is a relative-day dimension. OULAD does not provide exact calendar
-- presentation start dates, so converting offsets to invented dates would be
-- misleading. Bounds come from every date role used by the two facts, and
-- SEQUENCE fills gaps so every integer day in the interval has a key.
CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.dim_date')
USING DELTA
AS
WITH date_bounds AS (
  SELECT MIN(relative_day) AS minimum_day, MAX(relative_day) AS maximum_day
  FROM (
    SELECT assessment_date AS relative_day
    FROM IDENTIFIER(clean_namespace || '.assessments_clean')
    UNION ALL
    SELECT date_submitted
    FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
    UNION ALL
    SELECT activity_date
    FROM IDENTIFIER(clean_namespace || '.student_vle_clean')
  ) AS source_dates
  WHERE relative_day IS NOT NULL
),
relative_days AS (
  SELECT EXPLODE(SEQUENCE(minimum_day, maximum_day)) AS relative_day
  FROM date_bounds
)
SELECT
  SHA2(CAST(relative_day AS STRING), 256) AS date_key,
  relative_day,
  FLOOR(relative_day / 7) AS relative_week,
  CASE
    WHEN relative_day < 0 THEN 'BEFORE PRESENTATION'
    WHEN relative_day <= 28 THEN 'WEEKS 0-4'
    WHEN relative_day <= 84 THEN 'WEEKS 5-12'
    WHEN relative_day <= 168 THEN 'WEEKS 13-24'
    ELSE 'WEEK 25+'
  END AS course_phase
FROM relative_days;

-- These are role-playing views of one physical Date dimension, not extra
-- dimensions. They make BI joins readable while preserving the required count
-- of five physical dimensions.
CREATE OR REPLACE VIEW `ftw-week-07`.`03-mart`.dim_submission_date AS
SELECT
  date_key AS submission_date_key,
  relative_day AS submission_relative_day,
  relative_week AS submission_relative_week,
  course_phase AS submission_course_phase
FROM `ftw-week-07`.`03-mart`.dim_date;

CREATE OR REPLACE VIEW `ftw-week-07`.`03-mart`.dim_due_date AS
SELECT
  date_key AS due_date_key,
  relative_day AS due_relative_day,
  relative_week AS due_relative_week,
  course_phase AS due_course_phase
FROM `ftw-week-07`.`03-mart`.dim_date;

CREATE OR REPLACE VIEW `ftw-week-07`.`03-mart`.dim_activity_date AS
SELECT
  date_key AS activity_date_key,
  relative_day AS activity_relative_day,
  relative_week AS activity_relative_week,
  course_phase AS activity_course_phase
FROM `ftw-week-07`.`03-mart`.dim_date;