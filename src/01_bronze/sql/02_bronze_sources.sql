-- Databricks notebook source
-- Name: 02 - Bronze Sources
-- Purpose: Load the seven OULAD CSV files into typed, source-aligned Delta tables.
-- Grain: The original grain of each source file.
-- Depends on: 00_setup/01_setup.sql and a passing seven-file source check.
-- Produces: assessments, courses, student_assessment, student_info,
-- student_registration, student_vle, and vle in 01-raw.
-- Why: Bronze provides reproducible typed copies before relationship cleaning.
-- Rerun behavior: CREATE OR REPLACE performs a deterministic full refresh; it
-- does not append a second copy of the fixed homework snapshot.
-- Boundary: No cross-table joins or event deduplication occur in this layer.
-- Documentation: See src/README.md and tests/03_validate_bronze.sql.

-- source_path is declared in src/00_setup/01_setup.sql. Keeping that variable
-- lets the team change the Unity Catalog Volume location once in Setup without
-- silently resetting it in this ingestion step.
DECLARE OR REPLACE VARIABLE raw_namespace STRING
  DEFAULT '`ftw-week-07`.`01-raw`';

-- Shared READ_FILES choices used below:
-- header => true: the first CSV row contains column names.
-- explicit schema: prevents unstable type inference.
-- PERMISSIVE + _rescued_data: retains malformed source values for DQ checks.
-- TRIM and TRY_CAST: standardize values without aborting the entire load.
-- BIGINT is used for identifiers and DECIMAL for weights/scores so later facts
-- do not lose identifier range or decimal precision.

-- Assessments grain: one row per assessment definition.
-- date is the number of days relative to the module-presentation start; the
-- final column is named assessment_date to make that role explicit in Silver.
-- weight is the decimal percentage contribution to the course total.
CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.assessments')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_assessment AS BIGINT) AS id_assessment,
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
  -- Spark CSV schemas are positional, so this matches the source header order.
  schema => 'code_module STRING, code_presentation STRING, id_assessment BIGINT, assessment_type STRING, date STRING, weight DECIMAL(7, 3)'
);


-- Ingest courses.
-- Courses grain: one row per module + presentation; it becomes the parent
-- lookup used to conform course references in Silver.
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

-- Ingest student_assessment.
-- Submission grain: one row per student + assessment combination.
-- is_banked shows whether a score was carried forward from a previous attempt:
-- 0 = no and 1 = yes. Missing source scores use "?" and remain null; they are
-- monitored by the DQ suite rather than imputed.
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

-- Ingest student_info.
-- Enrollment grain: one student in one module presentation. This is wider than
-- stable student identity because demographics and outcomes are enrollment-level.
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

-- Ingest student_registration.
-- Registration grain: one student in one module presentation.
-- date_registration and date_unregistration are relative-day offsets; null
-- unregistration normally means the student did not unregister.
CREATE OR REPLACE TABLE IDENTIFIER(raw_namespace || '.student_registration')
USING DELTA
AS
SELECT
  TRIM(code_module) AS code_module,
  TRIM(code_presentation) AS code_presentation,
  TRY_CAST(id_student AS BIGINT) AS id_student,
  TRY_CAST(NULLIF(NULLIF(TRIM(date_registration), ''), '?') AS INT)
    AS date_registration,
  TRY_CAST(NULLIF(NULLIF(TRIM(date_unregistration), ''), '?') AS INT)
    AS date_unregistration,
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

-- Ingest student_vle (original team section retained).
-- Source grain: one recorded student interaction row. Repeated rows at the same
-- student + presentation + VLE site + relative day are expected here.
-- date is the number of days relative to the presentation start; the final
-- column is named activity_date. Silver combines repeated rows and sums clicks.
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

-- Ingest vle (original team section retained).
-- VLE grain: one site/resource inside one module presentation.
-- week_from and week_to are optional activity-availability offsets; "?" is
-- treated as a genuine missing value rather than a parsing failure.
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
