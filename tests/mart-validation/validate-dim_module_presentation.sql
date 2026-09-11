-- =====================================================================
-- DATA QUALITY VALIDATION FOR dim_module_presentation
-- =====================================================================
-- This script validates the dim_module_presentation table across four
-- DQ dimensions: Completeness, Uniqueness, Validity, and Referential Integrity
-- =====================================================================

WITH 

-- =====================================================================
-- 1. COMPLETENESS CHECKS
-- =====================================================================

completeness_module_presentation_key AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Completeness' AS dimension,
    'module_presentation_key - NULL Check' AS check_name,
    COUNT(*) FILTER (WHERE `module_presentation_key` IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `module_presentation_key` IS NULL) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `module_presentation_key` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

completeness_course_key AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Completeness' AS dimension,
    'course_key - NULL Check' AS check_name,
    COUNT(*) FILTER (WHERE `course_key` IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `course_key` IS NULL) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `course_key` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

completeness_code_module AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Completeness' AS dimension,
    'code_module - NULL Check' AS check_name,
    COUNT(*) FILTER (WHERE `code_module` IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `code_module` IS NULL) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `code_module` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

completeness_code_presentation AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Completeness' AS dimension,
    'code_presentation - NULL Check' AS check_name,
    COUNT(*) FILTER (WHERE `code_presentation` IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `code_presentation` IS NULL) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `code_presentation` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

completeness_module_presentation_length AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Completeness' AS dimension,
    'module_presentation_length - NULL Check' AS check_name,
    COUNT(*) FILTER (WHERE `module_presentation_length` IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `module_presentation_length` IS NULL) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `module_presentation_length` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

-- =====================================================================
-- 2. UNIQUENESS CHECKS
-- =====================================================================

uniqueness_module_presentation_key AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Uniqueness' AS dimension,
    'module_presentation_key - Primary Key Uniqueness' AS check_name,
    COUNT(*) - COUNT(DISTINCT `module_presentation_key`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `module_presentation_key`)) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) - COUNT(DISTINCT `module_presentation_key`) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
),

uniqueness_composite_key AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Uniqueness' AS dimension,
    'code_module + code_presentation - Composite Business Key Uniqueness' AS check_name,
    SUM(CASE WHEN duplicate_count > 1 THEN duplicate_count - 1 ELSE 0 END) AS failed_rows,
    SUM(duplicate_count) AS total_rows,
    ROUND((SUM(CASE WHEN duplicate_count > 1 THEN duplicate_count - 1 ELSE 0 END) * 100.0) / SUM(duplicate_count), 2) AS failure_rate,
    CASE 
      WHEN SUM(CASE WHEN duplicate_count > 1 THEN duplicate_count - 1 ELSE 0 END) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM (
    SELECT 
      `code_module`,
      `code_presentation`,
      COUNT(*) AS duplicate_count
    FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
    WHERE `code_module` IS NOT NULL AND `code_presentation` IS NOT NULL
    GROUP BY `code_module`, `code_presentation`
  )
),

-- =====================================================================
-- 3. VALIDITY CHECKS
-- =====================================================================

validity_code_presentation_format AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Validity' AS dimension,
    'code_presentation - Valid Format (YYYYB or YYYYJ)' AS check_name,
    COUNT(*) FILTER (WHERE `code_presentation` NOT IN ('2013B', '2013J', '2014B', '2014J')) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `code_presentation` NOT IN ('2013B', '2013J', '2014B', '2014J')) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `code_presentation` NOT IN ('2013B', '2013J', '2014B', '2014J')) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
  WHERE `code_presentation` IS NOT NULL
),

validity_code_module_format AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Validity' AS dimension,
    'code_module - Valid Format (3 uppercase letters)' AS check_name,
    COUNT(*) FILTER (WHERE `code_module` NOT RLIKE '^[A-Z]{3}$') AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `code_module` NOT RLIKE '^[A-Z]{3}$') * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `code_module` NOT RLIKE '^[A-Z]{3}$') * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
  WHERE `code_module` IS NOT NULL
),

validity_module_presentation_length_range AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Validity' AS dimension,
    'module_presentation_length - Valid Range (> 0 and <= 365)' AS check_name,
    COUNT(*) FILTER (WHERE `module_presentation_length` <= 0 OR `module_presentation_length` > 365) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `module_presentation_length` <= 0 OR `module_presentation_length` > 365) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `module_presentation_length` <= 0 OR `module_presentation_length` > 365) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
  WHERE `module_presentation_length` IS NOT NULL
),

validity_course_key_matches_code_module AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Validity' AS dimension,
    'course_key - Matches code_module' AS check_name,
    COUNT(*) FILTER (WHERE `course_key` != `code_module`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `course_key` != `code_module`) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `course_key` != `code_module`) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
  WHERE `course_key` IS NOT NULL AND `code_module` IS NOT NULL
),

validity_module_presentation_key_format AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Validity' AS dimension,
    'module_presentation_key - Valid Format (code_module-code_presentation)' AS check_name,
    COUNT(*) FILTER (WHERE `module_presentation_key` != CONCAT(`code_module`, '-', `code_presentation`)) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND((COUNT(*) FILTER (WHERE `module_presentation_key` != CONCAT(`code_module`, '-', `code_presentation`)) * 100.0) / COUNT(*), 2) AS failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `module_presentation_key` != CONCAT(`code_module`, '-', `code_presentation`)) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_module_presentation`
  WHERE `module_presentation_key` IS NOT NULL 
    AND `code_module` IS NOT NULL 
    AND `code_presentation` IS NOT NULL
),

-- =====================================================================
-- 4. REFERENTIAL INTEGRITY CHECKS
-- =====================================================================

referential_integrity_fact_assessments AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Referential Integrity' AS dimension,
    'FACT_ASSESSMENTS → DIM_MODULE_PRESENTATION FK Check' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`) AS total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
  WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`03-mart`.`dim_module_presentation` d
    WHERE d.`module_presentation_key` = f.`module_presentation_key`
  )
),

referential_integrity_fact_vle_interactions AS (
  SELECT
    'dim_module_presentation' AS table_name,
    'Referential Integrity' AS dimension,
    'FACT_VLE_INTERACTIONS → DIM_MODULE_PRESENTATION FK Check' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions`) AS total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions`), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions` f
  WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`03-mart`.`dim_module_presentation` d
    WHERE d.`module_presentation_key` = f.`module_presentation_key`
  )
),

-- =====================================================================
-- UNION ALL RESULTS
-- =====================================================================

all_checks AS (
  SELECT * FROM completeness_module_presentation_key
  UNION ALL
  SELECT * FROM completeness_course_key
  UNION ALL
  SELECT * FROM completeness_code_module
  UNION ALL
  SELECT * FROM completeness_code_presentation
  UNION ALL
  SELECT * FROM completeness_module_presentation_length
  UNION ALL
  SELECT * FROM uniqueness_module_presentation_key
  UNION ALL
  SELECT * FROM uniqueness_composite_key
  UNION ALL
  SELECT * FROM validity_code_presentation_format
  UNION ALL
  SELECT * FROM validity_code_module_format
  UNION ALL
  SELECT * FROM validity_module_presentation_length_range
  UNION ALL
  SELECT * FROM validity_course_key_matches_code_module
  UNION ALL
  SELECT * FROM validity_module_presentation_key_format
  UNION ALL
  SELECT * FROM referential_integrity_fact_assessments
  UNION ALL
  SELECT * FROM referential_integrity_fact_vle_interactions
)

-- =====================================================================
-- FINAL OUTPUT
-- =====================================================================

SELECT
  table_name,
  dimension,
  check_name,
  failed_rows,
  total_rows,
  failure_rate,
  status
FROM all_checks
ORDER BY 
  CASE dimension
    WHEN 'Completeness' THEN 1
    WHEN 'Uniqueness' THEN 2
    WHEN 'Validity' THEN 3
    WHEN 'Referential Integrity' THEN 4
  END,
  check_name;