%sql
-- Purpose: Persist clean-layer DQ results and stop on broken keys or relationships.
-- Grain: One row per data quality check and pipeline run.
-- Explanation: Declare session-scoped variables to parameterize schema names and run metadata.
-- Why variables? They allow the same SQL to work across environments (dev/staging/prod)
-- without hardcoding catalog/schema names throughout the query.

DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';  -- Source tables to validate
DECLARE OR REPLACE VARIABLE dq_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';  -- Where DQ results are stored
DECLARE OR REPLACE VARIABLE dq_run_id STRING DEFAULT UUID();  -- Unique ID for this validation run (groups all checks together)
DECLARE OR REPLACE VARIABLE dq_executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();  -- When this validation started

-- Create the results table if it doesn't exist (idempotent DDL pattern).
-- Why IDENTIFIER()? It allows dynamic table names from variables. Without it, Databricks would
-- treat the variable as a string literal rather than resolving it to the actual table name.
CREATE TABLE IF NOT EXISTS IDENTIFIER(dq_namespace || '.dq_check_results') (
  run_id STRING,                      -- Groups all checks from one validation run
  executed_at TIMESTAMP,              -- When the validation ran (audit trail)
  layer STRING,                       -- Data layer (BRONZE, SILVER, GOLD) for context
  dataset_name STRING,                -- Which table was checked
  column_name STRING,                 -- Which column(s) were validated
  check_name STRING,                  -- Human-readable check description
  quality_dimension STRING,           -- Category: UNIQUENESS, REFERENTIAL_INTEGRITY, COMPLETENESS, etc.
  check_type STRING,                  -- Technical type: UNIQUE, FOREIGN_KEY, NULL_RATE, etc.
  expectation STRING,                 -- What success looks like in plain language
  threshold_pct DECIMAL(7, 3),        -- Max allowed failure rate (0 = no tolerance, 1.0 = 1% allowed)
  severity STRING,                    -- CRITICAL (blocks pipeline) vs MEDIUM/LOW (warning only)
  check_owner STRING,                 -- Who to contact if this check fails
  total_count BIGINT,                 -- How many records were evaluated
  failed_count BIGINT,                -- How many records violated the rule
  passed_count BIGINT,                -- How many records passed
  score_pct DECIMAL(7, 3),            -- Pass rate percentage (100 = perfect)
  failure_pct DECIMAL(7, 3),          -- Failure rate percentage (0 = perfect)
  status STRING                       -- PASS, WARNING, or FAIL
);

-- Insert validation results for this run. Using a multi-part CTE structure:
-- 1. 'checks' CTE: Define and execute all validation rules (UNION ALL pattern)
-- 2. 'scored' CTE: Calculate pass/fail percentages
-- 3. 'classified' CTE: Assign status (PASS/WARNING/FAIL) based on thresholds
-- Why UNION ALL? It combines multiple independent checks into one result set efficiently.
-- Each SELECT in the UNION is one validation rule.

INSERT INTO IDENTIFIER(dq_namespace || '.dq_check_results')
WITH checks AS (
  
  -- CHECK 1: Verify the courses table has one row per (module, presentation) combination.
  -- Why STRUCT? It creates a composite key for multi-column uniqueness checks.
  -- If total_count != DISTINCT count, we have duplicates (grain violation).

  SELECT
    'courses_clean' AS dataset_name, 'code_module, code_presentation' AS column_name,
    'course grain is unique' AS check_name, 'UNIQUENESS' AS quality_dimension,
    'UNIQUE' AS check_type, 'One row per module and presentation' AS expectation,
    CAST(0 AS DECIMAL(7, 3)) AS threshold_pct,  -- Zero tolerance: any duplicate fails
    'CRITICAL' AS severity,  -- Duplicates break downstream joins, so this blocks the pipeline
    'data_engineering' AS check_owner, COUNT(*) AS total_count,
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)) AS failed_count  -- Duplicates = total - distinct
  FROM IDENTIFIER(clean_namespace || '.courses_clean')

  UNION ALL

  -- CHECK 2: Verify all assessments reference valid course presentations (foreign key integrity).
  -- Why LEFT JOIN + COUNT_IF(NULL)? This pattern finds orphaned records (assessments without a parent course).
  -- If course.code_module IS NULL after the join, the assessment's foreign key is invalid.

  SELECT
    'assessments_clean', 'code_module, code_presentation', 'all assessments match a course presentation',
    'REFERENTIAL_INTEGRITY', 'FOREIGN_KEY', 'Every assessment has a matching clean course presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*), COUNT_IF(course.code_module IS NULL)  -- Orphans = NULLs after LEFT JOIN
  FROM IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course
    ON assessment.code_module = course.code_module
    AND assessment.code_presentation = course.code_presentation

  UNION ALL

  -- CHECK 3: Verify the enrollment table has one row per (module, presentation, student).
  -- This is the grain that all student-level fact tables join to.

  SELECT
    'student_info_clean', 'code_module, code_presentation, id_student', 'student enrollment grain is unique',
    'UNIQUENESS', 'UNIQUE', 'One row per student and module presentation',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student))  -- Triple-column composite key
  FROM IDENTIFIER(clean_namespace || '.student_info_clean')

  UNION ALL

  -- CHECK 4: Verify all registration records reference valid student enrollments (three-column foreign key).
  -- A registration without a matching student enrollment indicates a data integrity break.

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

  -- CHECK 5: Combined uniqueness + dual foreign key check for submissions.
  -- Why combined? A submission must have (1) unique grain (student, assessment) AND
  -- (2) valid references to both assessment and enrollment tables.
  -- We add both violation counts: orphaned records + duplicate submissions.

  SELECT
    'student_assessment_clean', 'id_assessment, id_student',
    'submission grain and relationships are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One row per student-assessment and every submission matches assessment and enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(assessment.id_assessment IS NULL OR student.id_student IS NULL)  -- Orphans (failed foreign keys)
      + COUNT(*) - COUNT(DISTINCT STRUCT(submission.id_assessment, submission.id_student))  -- Duplicates (grain violations)
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean') AS submission
  LEFT JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
    ON submission.id_assessment = assessment.id_assessment
  LEFT JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student  -- Join through assessment to validate enrollment
    ON assessment.code_module = student.code_module
    AND assessment.code_presentation = student.code_presentation
    AND submission.id_student = student.id_student

  UNION ALL

  -- CHECK 6: Combined check for VLE (Virtual Learning Environment) interactions.
  -- Validates: (1) five-column unique grain, (2) foreign keys to activity and student tables,
  -- (3) business rule: click counts must be positive (sum_click > 0).
  -- Why include sum_click? Negative or zero clicks indicate corrupted aggregation.

  SELECT
    'student_vle_clean', 'code_module, code_presentation, id_student, id_site, activity_date',
    'daily VLE grain and relationships are valid', 'REFERENTIAL_INTEGRITY', 'UNIQUE_FOREIGN_KEY',
    'One positive row per student, site, and relative day with matching activity and enrollment',
    0, 'CRITICAL', 'data_engineering', COUNT(*),
    COUNT_IF(activity.id_site IS NULL OR student.id_student IS NULL OR interaction.sum_click <= 0)  -- FK violations + invalid clicks
      + COUNT(*) - COUNT(DISTINCT STRUCT(  -- Plus duplicates at the five-column grain
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

  -- CHECK 7: Monitor missing scores (NULL rate). This is NOT CRITICAL because some nulls are expected
  -- (e.g., late submissions not yet graded, withdrawn students). We set a 1% threshold.
  -- Why MEDIUM severity? It warns us if nulls spike but doesn't block the pipeline.

  SELECT
    'student_assessment_clean', 'score', 'score null rate is monitored',
    'COMPLETENESS', 'NULL_RATE', 'Missing scores remain at or below 1 percent',
    CAST(1.0 AS DECIMAL(7, 3)),  -- Threshold: 1% null rate is acceptable
    'MEDIUM', 'analytics', COUNT(*), COUNT_IF(score IS NULL)
  FROM IDENTIFIER(clean_namespace || '.student_assessment_clean')
),

-- CTE 2: Calculate percentages from raw counts.
-- Why CASE WHEN total_count = 0? Prevents division by zero if a table is empty.
-- Why GREATEST(..., 0)? Defensive: ensures passed_count never goes negative due to logic bugs.

scored AS (
  SELECT
    *,
    CAST(CASE WHEN total_count = 0 THEN 100.0 ELSE 100.0 * failed_count / total_count END AS DECIMAL(7, 3))
      AS failure_pct,  -- What percentage failed? (Higher = worse)
    CAST(CASE WHEN total_count = 0 THEN 0.0
      ELSE 100.0 * GREATEST(total_count - failed_count, 0) / total_count END AS DECIMAL(7, 3)) AS score_pct  -- What percentage passed? (Higher = better)
  FROM checks
),

-- CTE 3: Classify each check as PASS, WARNING, or FAIL based on threshold.
-- FAIL: Empty table (total_count = 0) OR failure rate exceeds threshold.
-- WARNING: Some failures but still within threshold (e.g., 0.1% nulls when 1% is allowed).
-- PASS: Zero failures.

classified AS (
  SELECT
    *,
    CASE WHEN total_count = 0 OR failure_pct > threshold_pct THEN 'FAIL'  -- Over threshold = failure
      WHEN failed_count > 0 THEN 'WARNING'  -- Non-zero but within threshold = warning
      ELSE 'PASS' END AS status  -- Zero failures = pass
  FROM scored
)

-- Final SELECT: Insert all classified checks into the DQ results table.
-- Why 'SILVER'? This validation runs on the clean layer (silver/refined layer in medallion architecture).

SELECT
  dq_run_id, dq_executed_at, 'SILVER', dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity, check_owner,
  total_count, failed_count, GREATEST(total_count - failed_count, 0), score_pct, failure_pct, status
FROM classified;

-- Quality Gate: Stop the pipeline if ANY critical check failed.
-- Why ASSERT_TRUE? It throws an error and halts execution when the condition is false.
-- Why OVER ()? The window function counts across ALL rows in this run, so every row sees
-- the same count and either all pass or all fail together (consistent gate behavior).
-- This ensures broken referential integrity or duplicate keys stop the pipeline immediately.

SELECT
  dataset_name,
  check_name,
  status,
  failed_count,
  ASSERT_TRUE(  -- Throws error if condition is FALSE
    COUNT_IF(status = 'FAIL' AND severity = 'CRITICAL') OVER () = 0,  -- "No critical failures exist"
    'critical Silver data quality check failed; inspect 04-analytics.dq_check_results'  -- Error message shown to user
  ) AS silver_quality_gate
FROM IDENTIFIER(dq_namespace || '.dq_check_results')
WHERE run_id = dq_run_id AND layer = 'SILVER'  -- Only this run's checks
ORDER BY dataset_name, check_name;