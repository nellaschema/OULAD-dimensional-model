-- ================================================================
-- COMPREHENSIVE DATA VALIDATION: dim_date
-- Table: `ftw-week-07`.`03-mart`.dim_date
-- Type: Relative Date Dimension (course-based timeline)
-- Schema: date_key (STRING PK), relative_week (INT), relative_day (INT), course_phase (STRING)
-- ================================================================

-- ================================================================
-- 1. ROW COUNT & BASIC STATS
-- ================================================================
SELECT 
  'Row Count Check' AS validation_test,
  COUNT(*) AS actual_count,
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN COUNT(*) = 0 THEN 'Table is empty'
    ELSE CONCAT('Table contains ', COUNT(*), ' date records')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

SELECT 
  'Date Range Summary' AS validation_test,
  MIN(CAST(date_key AS INT)) AS min_date_key,
  MAX(CAST(date_key AS INT)) AS max_date_key,
  MAX(CAST(date_key AS INT)) - MIN(CAST(date_key AS INT)) + 1 AS expected_days,
  COUNT(*) AS actual_days,
  COUNT(DISTINCT course_phase) AS distinct_phases,
  CASE 
    WHEN COUNT(*) = MAX(CAST(date_key AS INT)) - MIN(CAST(date_key AS INT)) + 1 THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN COUNT(*) = MAX(CAST(date_key AS INT)) - MIN(CAST(date_key AS INT)) + 1 
    THEN 'Complete date sequence with no gaps'
    ELSE CONCAT('Missing ', (MAX(CAST(date_key AS INT)) - MIN(CAST(date_key AS INT)) + 1) - COUNT(*), ' days in sequence')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- ================================================================
-- 2. NULL VALUE CHECKS
-- ================================================================
SELECT 
  'NULL Check - date_key' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) AS null_count,
  CASE 
    WHEN SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) > 0 
    THEN CONCAT('Found ', SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END), ' NULL values in date_key')
    ELSE 'No NULL values in date_key'
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

SELECT 
  'NULL Check - relative_week' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN relative_week IS NULL THEN 1 ELSE 0 END) AS null_count,
  CASE 
    WHEN SUM(CASE WHEN relative_week IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN relative_week IS NULL THEN 1 ELSE 0 END) > 0 
    THEN CONCAT('Found ', SUM(CASE WHEN relative_week IS NULL THEN 1 ELSE 0 END), ' NULL values in relative_week')
    ELSE 'No NULL values in relative_week'
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

SELECT 
  'NULL Check - relative_day' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN relative_day IS NULL THEN 1 ELSE 0 END) AS null_count,
  CASE 
    WHEN SUM(CASE WHEN relative_day IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN relative_day IS NULL THEN 1 ELSE 0 END) > 0 
    THEN CONCAT('Found ', SUM(CASE WHEN relative_day IS NULL THEN 1 ELSE 0 END), ' NULL values in relative_day')
    ELSE 'No NULL values in relative_day'
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

SELECT 
  'NULL Check - course_phase' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN course_phase IS NULL THEN 1 ELSE 0 END) AS null_count,
  CASE 
    WHEN SUM(CASE WHEN course_phase IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN course_phase IS NULL THEN 1 ELSE 0 END) > 0 
    THEN CONCAT('Found ', SUM(CASE WHEN course_phase IS NULL THEN 1 ELSE 0 END), ' NULL values in course_phase')
    ELSE 'No NULL values in course_phase'
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- ================================================================
-- 3. UNIQUENESS CHECKS (Primary Key Validation)
-- ================================================================
SELECT 
  'Uniqueness Check - date_key' AS validation_test,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT date_key) AS distinct_count,
  COUNT(*) - COUNT(DISTINCT date_key) AS duplicate_count,
  CASE 
    WHEN COUNT(*) = COUNT(DISTINCT date_key) THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN COUNT(*) = COUNT(DISTINCT date_key) THEN 'All date_key values are unique'
    ELSE CONCAT('Found ', COUNT(*) - COUNT(DISTINCT date_key), ' duplicate date_key values')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- Show duplicate date_keys if any exist
SELECT 
  'Duplicate date_key Details' AS validation_test,
  date_key,
  COUNT(*) AS occurrence_count
FROM `ftw-week-07`.`03-mart`.dim_date
GROUP BY date_key
HAVING COUNT(*) > 1;

SELECT 
  'Uniqueness Check - relative_day' AS validation_test,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT relative_day) AS distinct_count,
  COUNT(*) - COUNT(DISTINCT relative_day) AS duplicate_count,
  CASE 
    WHEN COUNT(*) = COUNT(DISTINCT relative_day) THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN COUNT(*) = COUNT(DISTINCT relative_day) THEN 'All relative_day values are unique'
    ELSE CONCAT('Found ', COUNT(*) - COUNT(DISTINCT relative_day), ' duplicate relative_day values')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- ================================================================
-- 4. DATE SEQUENCE CONTINUITY CHECK
-- ================================================================
-- Check for gaps in the date sequence
WITH date_sequence AS (
  SELECT 
    CAST(date_key AS INT) AS date_key_int,
    CAST(date_key AS INT) - LAG(CAST(date_key AS INT)) OVER (ORDER BY CAST(date_key AS INT)) AS gap
  FROM `ftw-week-07`.`03-mart`.dim_date
)
SELECT 
  'Date Sequence Continuity' AS validation_test,
  COUNT(*) AS total_transitions,
  SUM(CASE WHEN gap IS NOT NULL AND gap > 1 THEN 1 ELSE 0 END) AS gap_count,
  CASE 
    WHEN SUM(CASE WHEN gap IS NOT NULL AND gap > 1 THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN gap IS NOT NULL AND gap > 1 THEN 1 ELSE 0 END) = 0 
    THEN 'Date sequence is continuous with no gaps'
    ELSE CONCAT('Found ', SUM(CASE WHEN gap IS NOT NULL AND gap > 1 THEN 1 ELSE 0 END), ' gaps in date sequence')
  END AS message
FROM date_sequence;

-- Show gaps if any exist
WITH date_sequence AS (
  SELECT 
    CAST(date_key AS INT) AS date_key_int,
    CAST(date_key AS INT) - LAG(CAST(date_key AS INT)) OVER (ORDER BY CAST(date_key AS INT)) AS gap
  FROM `ftw-week-07`.`03-mart`.dim_date
)
SELECT 
  'Gap Details' AS validation_test,
  date_key_int AS date_after_gap,
  gap AS gap_size,
  date_key_int - gap AS date_before_gap
FROM date_sequence
WHERE gap > 1
ORDER BY date_key_int;

-- ================================================================
-- 5. DATA CONSISTENCY CHECKS
-- ================================================================
-- Verify date_key matches relative_day
SELECT 
  'Consistency - date_key vs relative_day' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN CAST(date_key AS INT) = relative_day THEN 1 ELSE 0 END) AS matching_count,
  SUM(CASE WHEN CAST(date_key AS INT) != relative_day THEN 1 ELSE 0 END) AS mismatched_count,
  CASE 
    WHEN COUNT(*) = SUM(CASE WHEN CAST(date_key AS INT) = relative_day THEN 1 ELSE 0 END) THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN COUNT(*) = SUM(CASE WHEN CAST(date_key AS INT) = relative_day THEN 1 ELSE 0 END) 
    THEN 'date_key matches relative_day for all records'
    ELSE CONCAT('Found ', SUM(CASE WHEN CAST(date_key AS INT) != relative_day THEN 1 ELSE 0 END), ' mismatched records')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- Show mismatched records if any
SELECT 
  'Mismatch Details - date_key vs relative_day' AS validation_test,
  date_key,
  relative_day,
  course_phase
FROM `ftw-week-07`.`03-mart`.dim_date
WHERE CAST(date_key AS INT) != relative_day
ORDER BY CAST(date_key AS INT)
LIMIT 20;

-- Verify relative_week calculation (should be relative_day div 7)
SELECT 
  'Consistency - relative_week calculation' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN relative_week = FLOOR(relative_day / 7.0) THEN 1 ELSE 0 END) AS correct_count,
  SUM(CASE WHEN relative_week != FLOOR(relative_day / 7.0) THEN 1 ELSE 0 END) AS incorrect_count,
  CASE 
    WHEN COUNT(*) = SUM(CASE WHEN relative_week = FLOOR(relative_day / 7.0) THEN 1 ELSE 0 END) THEN 'PASS'
    ELSE 'FAIL' 
  END AS status,
  CASE 
    WHEN COUNT(*) = SUM(CASE WHEN relative_week = FLOOR(relative_day / 7.0) THEN 1 ELSE 0 END) 
    THEN 'relative_week correctly calculated for all records'
    ELSE CONCAT('Found ', SUM(CASE WHEN relative_week != FLOOR(relative_day / 7.0) THEN 1 ELSE 0 END), ' incorrect relative_week values')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- Show incorrect calculations if any
SELECT 
  'Incorrect relative_week Details' AS validation_test,
  date_key,
  relative_day,
  relative_week AS actual_week,
  FLOOR(relative_day / 7.0) AS expected_week,
  course_phase
FROM `ftw-week-07`.`03-mart`.dim_date
WHERE relative_week != FLOOR(relative_day / 7.0)
ORDER BY CAST(date_key AS INT)
LIMIT 20;

-- ================================================================
-- 6. COURSE PHASE VALIDATION
-- ================================================================
-- Check Pre-course phase (negative days)
SELECT 
  'Phase Check - Pre-course' AS validation_test,
  COUNT(*) AS precourse_records,
  SUM(CASE WHEN relative_day < 0 AND course_phase = 'Pre-course' THEN 1 ELSE 0 END) AS correct_count,
  SUM(CASE WHEN relative_day < 0 AND course_phase != 'Pre-course' THEN 1 ELSE 0 END) AS incorrect_count,
  CASE 
    WHEN SUM(CASE WHEN relative_day < 0 AND course_phase != 'Pre-course' THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN relative_day < 0 AND course_phase != 'Pre-course' THEN 1 ELSE 0 END) = 0 
    THEN 'All negative days correctly marked as Pre-course'
    ELSE CONCAT('Found ', SUM(CASE WHEN relative_day < 0 AND course_phase != 'Pre-course' THEN 1 ELSE 0 END), ' incorrect Pre-course assignments')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date
WHERE relative_day < 0;

-- Check course phase naming pattern for positive days
SELECT 
  'Phase Check - Week Naming Pattern' AS validation_test,
  COUNT(*) AS course_day_records,
  SUM(CASE 
    WHEN relative_day >= 0 AND (
      course_phase = CONCAT('Week ', CAST(FLOOR(relative_day / 7.0) + 1 AS STRING))
      OR (relative_day >= 0 AND relative_day < 7 AND course_phase = 'Week 1')
    ) THEN 1 ELSE 0 END) AS correct_count,
  SUM(CASE 
    WHEN relative_day >= 0 AND NOT (
      course_phase = CONCAT('Week ', CAST(FLOOR(relative_day / 7.0) + 1 AS STRING))
      OR (relative_day >= 0 AND relative_day < 7 AND course_phase = 'Week 1')
    ) THEN 1 ELSE 0 END) AS incorrect_count,
  CASE 
    WHEN SUM(CASE 
      WHEN relative_day >= 0 AND NOT (
        course_phase = CONCAT('Week ', CAST(FLOOR(relative_day / 7.0) + 1 AS STRING))
        OR (relative_day >= 0 AND relative_day < 7 AND course_phase = 'Week 1')
      ) THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status
FROM `ftw-week-07`.`03-mart`.dim_date
WHERE relative_day >= 0;

-- List all distinct course phases
SELECT 
  'Course Phase Distribution' AS validation_test,
  course_phase,
  COUNT(*) AS day_count,
  MIN(relative_day) AS min_day,
  MAX(relative_day) AS max_day
FROM `ftw-week-07`.`03-mart`.dim_date
GROUP BY course_phase
ORDER BY MIN(relative_day);

-- ================================================================
-- 7. DATA TYPE & FORMAT VALIDATION
-- ================================================================
-- Verify date_key can be cast to integer
SELECT 
  'Format Check - date_key castability' AS validation_test,
  COUNT(*) AS total_rows,
  SUM(CASE 
    WHEN TRY_CAST(date_key AS INT) IS NULL THEN 1 
    ELSE 0 
  END) AS non_castable_count,
  CASE 
    WHEN SUM(CASE WHEN TRY_CAST(date_key AS INT) IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN TRY_CAST(date_key AS INT) IS NULL THEN 1 ELSE 0 END) = 0 
    THEN 'All date_key values can be cast to integer'
    ELSE CONCAT('Found ', SUM(CASE WHEN TRY_CAST(date_key AS INT) IS NULL THEN 1 ELSE 0 END), ' non-integer date_key values')
  END AS message
FROM `ftw-week-07`.`03-mart`.dim_date;

-- Show non-castable values if any
SELECT 
  'Non-castable date_key Details' AS validation_test,
  date_key,
  relative_day,
  course_phase
FROM `ftw-week-07`.`03-mart`.dim_date
WHERE TRY_CAST(date_key AS INT) IS NULL;

-- ================================================================
-- 8. WEEK BOUNDARY CHECKS
-- ================================================================
-- Verify each week has exactly 7 days (except possibly first/last)
WITH week_counts AS (
  SELECT 
    relative_week,
    course_phase,
    COUNT(*) AS days_in_week,
    MIN(relative_day) AS first_day,
    MAX(relative_day) AS last_day
  FROM `ftw-week-07`.`03-mart`.dim_date
  WHERE relative_day >= 0
  GROUP BY relative_week, course_phase
)
SELECT 
  'Week Size Validation' AS validation_test,
  COUNT(*) AS total_weeks,
  SUM(CASE WHEN days_in_week = 7 THEN 1 ELSE 0 END) AS complete_weeks,
  SUM(CASE WHEN days_in_week < 7 THEN 1 ELSE 0 END) AS incomplete_weeks,
  CASE 
    WHEN SUM(CASE WHEN days_in_week != 7 THEN 1 ELSE 0 END) <= 1 THEN 'PASS'
    ELSE 'WARNING'
  END AS status,
  CASE 
    WHEN SUM(CASE WHEN days_in_week != 7 THEN 1 ELSE 0 END) = 0 
    THEN 'All weeks contain exactly 7 days'
    WHEN SUM(CASE WHEN days_in_week != 7 THEN 1 ELSE 0 END) = 1 
    THEN 'All weeks complete except last week (acceptable)'
    ELSE CONCAT('Found ', SUM(CASE WHEN days_in_week != 7 THEN 1 ELSE 0 END), ' incomplete weeks')
  END AS message
FROM week_counts;

-- Show incomplete weeks
WITH week_counts AS (
  SELECT 
    relative_week,
    course_phase,
    COUNT(*) AS days_in_week,
    MIN(relative_day) AS first_day,
    MAX(relative_day) AS last_day
  FROM `ftw-week-07`.`03-mart`.dim_date
  WHERE relative_day >= 0
  GROUP BY relative_week, course_phase
)
SELECT 
  'Incomplete Week Details' AS validation_test,
  relative_week,
  course_phase,
  days_in_week,
  first_day,
  last_day
FROM week_counts
WHERE days_in_week != 7
ORDER BY relative_week;

-- ================================================================
-- 9. REFERENTIAL INTEGRITY - FACT TABLE RELATIONSHIPS
-- ================================================================
-- Check orphaned dates in fact_vle_interactions (via date foreign key)
SELECT 
  'Referential Integrity - fact_vle_interactions' AS validation_test,
  COUNT(DISTINCT svc.activity_date) AS distinct_dates_in_fact,
  COUNT(DISTINCT dd.date_key) AS matched_in_dim,
  COUNT(DISTINCT svc.activity_date) - COUNT(DISTINCT dd.date_key) AS orphaned_count,
  CASE 
    WHEN COUNT(DISTINCT svc.activity_date) = COUNT(DISTINCT dd.date_key) THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN COUNT(DISTINCT svc.activity_date) = COUNT(DISTINCT dd.date_key) 
    THEN 'All VLE interaction dates exist in dimension'
    ELSE CONCAT(COUNT(DISTINCT svc.activity_date) - COUNT(DISTINCT dd.date_key), ' orphaned dates in fact_vle_interactions')
  END AS message
FROM `ftw-week-07`.`02-clean`.student_vle_clean svc
LEFT JOIN `ftw-week-07`.`03-mart`.dim_date dd ON CAST(svc.activity_date AS STRING) = dd.date_key;

-- Show orphaned dates if any
SELECT 
  'Orphaned Date Details - fact_vle_interactions' AS validation_test,
  svc.activity_date,
  COUNT(*) AS record_count
FROM `ftw-week-07`.`02-clean`.student_vle_clean svc
LEFT JOIN `ftw-week-07`.`03-mart`.dim_date dd ON CAST(svc.activity_date AS STRING) = dd.date_key
WHERE dd.date_key IS NULL
GROUP BY svc.activity_date
ORDER BY svc.activity_date
LIMIT 20;

-- Check orphaned submission dates in fact_assessments
SELECT 
  'Referential Integrity - fact_assessments (submission_date)' AS validation_test,
  COUNT(DISTINCT sac.date_submitted) AS distinct_dates_in_fact,
  COUNT(DISTINCT dd.date_key) AS matched_in_dim,
  COUNT(DISTINCT sac.date_submitted) - COUNT(DISTINCT dd.date_key) AS orphaned_count,
  CASE 
    WHEN COUNT(DISTINCT sac.date_submitted) = COUNT(DISTINCT dd.date_key) THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  CASE 
    WHEN COUNT(DISTINCT sac.date_submitted) = COUNT(DISTINCT dd.date_key) 
    THEN 'All assessment submission dates exist in dimension'
    ELSE CONCAT(COUNT(DISTINCT sac.date_submitted) - COUNT(DISTINCT dd.date_key), ' orphaned dates in fact_assessments')
  END AS message
FROM `ftw-week-07`.`02-clean`.student_assessment_clean sac
LEFT JOIN `ftw-week-07`.`03-mart`.dim_date dd ON CAST(sac.date_submitted AS STRING) = dd.date_key
WHERE sac.date_submitted IS NOT NULL;

-- Show orphaned submission dates
SELECT 
  'Orphaned Submission Date Details - fact_assessments' AS validation_test,
  sac.date_submitted,
  COUNT(*) AS record_count
FROM `ftw-week-07`.`02-clean`.student_assessment_clean sac
LEFT JOIN `ftw-week-07`.`03-mart`.dim_date dd ON CAST(sac.date_submitted AS STRING) = dd.date_key
WHERE dd.date_key IS NULL AND sac.date_submitted IS NOT NULL
GROUP BY sac.date_submitted
ORDER BY sac.date_submitted
LIMIT 20;

-- ================================================================
-- 10. SUMMARY VALIDATION REPORT
-- ================================================================
SELECT 
  'SUMMARY VALIDATION REPORT' AS report_title,
  COUNT(*) AS total_date_records,
  COUNT(DISTINCT date_key) AS distinct_date_keys,
  COUNT(DISTINCT relative_day) AS distinct_relative_days,
  COUNT(DISTINCT course_phase) AS distinct_phases,
  MIN(CAST(date_key AS INT)) AS min_date_key,
  MAX(CAST(date_key AS INT)) AS max_date_key,
  SUM(CASE WHEN relative_day < 0 THEN 1 ELSE 0 END) AS precourse_days,
  SUM(CASE WHEN relative_day >= 0 THEN 1 ELSE 0 END) AS course_days,
  SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) AS null_date_keys,
  SUM(CASE WHEN course_phase IS NULL THEN 1 ELSE 0 END) AS null_phases
FROM `ftw-week-07`.`03-mart`.dim_date;