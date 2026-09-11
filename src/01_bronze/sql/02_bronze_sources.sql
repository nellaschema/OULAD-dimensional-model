-- Databricks notebook source
-- Name: 02 - Bronze Sources
-- Purpose: Load the seven OULAD CSV files into typed, source-aligned Delta tables.
-- Grain: The original grain of each source file.

-- Explanation: source_path is declared by src/00_setup/01_setup.sql. Keeping its
-- value here lets the team override the configured Volume path in Setup without
-- this ingestion step silently resetting it.
DECLARE OR REPLACE VARIABLE raw_namespace STRING DEFAULT '`ftw-week-07`.`01-raw`';

-- Explanation: READ_FILES options for robust CSV parsing:
-- - format => 'csv': Parse as CSV format
-- - header => true: First row contains column names
-- - quote => '"': Fields wrapped in double quotes when they contain special chars
-- - escape => '"': Double-quote to escape quotes within fields (standard CSV)
-- - mode => 'PERMISSIVE': Continue on malformed rows, store bad data in _rescued_data
-- - rescuedDataColumn: Column name for rescued malformed data
-- - schema: Explicit schema ensures correct type inference
CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.courses')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(module_presentation_length AS INT) AS module_presentation_length,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/courses.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, module_presentation_length INT'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.assessments')
USING DELTA
AS
SELECT
  TRY_CAST(id_assessment AS BIGINT) AS id_assessment,
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRIM(assessment_type) AS assessment_type,
  TRY_CAST(NULLIF(NULLIF(TRIM(date), ''), '?') AS INT) AS assessment_date,
  TRY_CAST(weight AS DECIMAL(7, 3)) AS weight,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/assessments.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  -- CSV schemas are positional in Spark, so this order must match the file header.
  schema => 'code_module STRING, code_presentation STRING, id_assessment BIGINT, assessment_type STRING, date STRING, weight DECIMAL(7, 3)'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.vle')
USING DELTA
AS
SELECT
  TRY_CAST(id_site AS BIGINT) AS id_site,
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRIM(activity_type) AS activity_type,
  TRY_CAST(NULLIF(NULLIF(TRIM(week_from), ''), '?') AS INT) AS week_from,
  TRY_CAST(NULLIF(NULLIF(TRIM(week_to), ''), '?') AS INT) AS week_to,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/vle.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'id_site BIGINT, code_module STRING, code_presentation STRING, activity_type STRING, week_from STRING, week_to STRING'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.student_info')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRIM(gender) AS gender,
  TRIM(region) AS region,
  TRIM(highest_education) AS highest_education,
  NULLIF(NULLIF(TRIM(imd_band), ''), '?') AS imd_band,
  TRIM(age_band) AS age_band,
  TRY_CAST(num_of_prev_attempts AS INT) AS num_of_prev_attempts,
  TRY_CAST(studied_credits AS INT) AS studied_credits,
  TRIM(disability) AS disability,
  TRIM(final_result) AS final_result,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/studentInfo.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, gender STRING, region STRING, highest_education STRING, imd_band STRING, age_band STRING, num_of_prev_attempts INT, studied_credits INT, disability STRING, final_result STRING'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.student_registration')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(NULLIF(NULLIF(TRIM(date_registration), ''), '?') AS INT) AS date_registration,
  TRY_CAST(NULLIF(NULLIF(TRIM(date_unregistration), ''), '?') AS INT) AS date_unregistration,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/studentRegistration.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, date_registration STRING, date_unregistration STRING'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.student_assessment')
USING DELTA
AS
SELECT
  TRY_CAST(id_assessment AS BIGINT) AS id_assessment,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(NULLIF(NULLIF(TRIM(date_submitted), ''), '?') AS INT) AS date_submitted,
  TRY_CAST(is_banked AS INT) AS is_banked,
  TRY_CAST(NULLIF(NULLIF(TRIM(score), ''), '?') AS DECIMAL(7, 3)) AS score,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/studentAssessment.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'id_assessment BIGINT, id_student BIGINT, date_submitted STRING, is_banked INT, score STRING'
);

CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.student_vle')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(id_site AS BIGINT) AS id_site,
  TRY_CAST(date AS INT) AS activity_date,
  TRY_CAST(sum_click AS BIGINT) AS sum_click,
  _rescued_data,
  _metadata.file_path AS source_file,
  CURRENT_TIMESTAMP() AS ingested_at
FROM READ_FILES(
  source_path || '/studentVle.csv',
  format => 'csv',
  header => true,
  quote => '"',
  escape => '"',
  mode => 'PERMISSIVE',
  rescuedDataColumn => '_rescued_data',
  schema => 'code_module STRING, code_presentation STRING, id_student BIGINT, id_site BIGINT, date INT, sum_click BIGINT'
);
