-- Databricks notebook source
-- Name: 01 - Setup
-- Purpose: Configure the run, create layer schemas, and verify the seven required OULAD files.
-- Grain: One validation row for the configured source directory.

-- Explanation: Declare session variables to centralize configuration.
-- OR REPLACE ensures the variable is updated if it already exists from a previous run.
DECLARE OR REPLACE VARIABLE source_path STRING
  DEFAULT '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07';
DECLARE OR REPLACE VARIABLE raw_namespace STRING DEFAULT '`ftw-week-07`.`01-raw`';
DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';
DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`05-data-quality`';
-- Explanation: UUID() generates a unique identifier for this data quality run
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();
-- Explanation: CURRENT_TIMESTAMP() captures the exact execution time of this run
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Explanation: IDENTIFIER() function allows using a variable as a schema name.
-- This enables dynamic schema creation based on the variables defined above.
-- IF NOT EXISTS prevents errors if the schema already exists.
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(raw_namespace);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(clean_namespace);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(mart_namespace);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(analytics_namespace);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(dq_namespace);

-- Explanation: Create a centralized table to store all data quality check results.
-- The || operator concatenates the namespace variable with the table name.
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

-- Explanation: CTE (Common Table Expression) to define the seven required OULAD files.
-- EXPLODE() converts the array into individual rows, one per filename.
WITH expected_files AS (
  SELECT EXPLODE(
    ARRAY(
      'assessments.csv',
      'courses.csv',
      'studentAssessment.csv',
      'studentInfo.csv',
      'studentRegistration.csv',
      'studentVle.csv',
      'vle.csv'
    )
  ) AS file_name
),
-- Explanation: CTE to list actual files found in the source directory.
-- READ_FILES() reads file metadata from the volume path.
-- REGEXP_EXTRACT(path, '[^/]+$', 0) extracts just the filename from the full path.
-- Pattern '[^/]+$' matches one or more non-slash characters at the end of the string.
actual_files AS (
  SELECT DISTINCT REGEXP_EXTRACT(files.path, '[^/]+$', 0) AS file_name
  FROM READ_FILES(
    source_path || '/*.csv',
    format => 'binaryFile'
  ) AS files
),
-- Explanation: CTE to calculate file validation metrics.
file_checks AS (
  SELECT
    (SELECT COUNT(*) FROM actual_files) AS actual_file_count,
    -- Explanation: LEFT ANTI JOIN returns rows from the left table that have NO match in the right table.
    -- This finds actual files that are NOT in the expected list (unexpected files).
    (
      SELECT COUNT(*)
      FROM actual_files AS actual
      LEFT ANTI JOIN expected_files AS expected
        ON actual.file_name = expected.file_name
    ) AS unexpected_file_count,
    -- Explanation: This finds expected files that are NOT in the actual list (missing files).
    (
      SELECT COUNT(*)
      FROM expected_files AS expected
      LEFT ANTI JOIN actual_files AS actual
        ON expected.file_name = actual.file_name
    ) AS missing_file_count
)
-- Explanation: Final SELECT returns validation results and enforces data quality checks.
-- ASSERT_TRUE() throws an error if the condition is false, halting execution.
-- This ensures all required files are present before proceeding with data ingestion.
SELECT
  actual_file_count,
  unexpected_file_count,
  missing_file_count,
  ASSERT_TRUE(actual_file_count = 7, 'source folder must contain exactly seven CSV files') AS file_count_check,
  ASSERT_TRUE(unexpected_file_count = 0, 'source folder contains an unexpected CSV file') AS unexpected_file_check,
  ASSERT_TRUE(missing_file_count = 0, 'one or more required source files are missing') AS missing_file_check
FROM file_checks;
