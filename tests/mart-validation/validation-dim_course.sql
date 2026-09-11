-- =====================================================
-- DATA QUALITY VALIDATION FOR dim_course
-- =====================================================
-- This SQL performs comprehensive data quality checks across 4 dimensions:
-- 1. Completeness (NULL and empty string checks)
-- 2. Uniqueness (Primary key and business key validation)
-- 3. Validity (Format and consistency checks)
-- 4. Referential Integrity (Not applicable for this dimension table)
-- =====================================================

WITH total_count AS (
  SELECT COUNT(*) as total_rows FROM `ftw-week-07`.`03-mart`.`dim_course`
),

-- =====================================================
-- COMPLETENESS CHECKS
-- =====================================================
completeness_course_key_null AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Completeness' as dimension,
    'course_key should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `course_key` IS NULL
),

completeness_code_module_null AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Completeness' as dimension,
    'code_module should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `code_module` IS NULL
),

completeness_course_key_empty AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Completeness' as dimension,
    'course_key should not be empty string' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `course_key` IS NOT NULL AND TRIM(`course_key`) = ''
),

completeness_code_module_empty AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Completeness' as dimension,
    'code_module should not be empty string' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `code_module` IS NOT NULL AND TRIM(`code_module`) = ''
),

-- =====================================================
-- UNIQUENESS CHECKS
-- =====================================================
uniqueness_course_key AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Uniqueness' as dimension,
    'course_key should be unique (primary key)' as check_name,
    COUNT(*) - COUNT(DISTINCT `course_key`) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `course_key`)) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN COUNT(*) - COUNT(DISTINCT `course_key`) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
),

uniqueness_code_module AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Uniqueness' as dimension,
    'code_module should be unique' as check_name,
    COUNT(*) - COUNT(DISTINCT `code_module`) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `code_module`)) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN COUNT(*) - COUNT(DISTINCT `code_module`) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
),

-- =====================================================
-- VALIDITY CHECKS
-- =====================================================
validity_course_key_format AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Validity' as dimension,
    'course_key should be 3 uppercase letters' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `course_key` IS NOT NULL 
    AND NOT REGEXP_LIKE(`course_key`, '^[A-Z]{3}$')
),

validity_code_module_format AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Validity' as dimension,
    'code_module should be 3 uppercase letters' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `code_module` IS NOT NULL 
    AND NOT REGEXP_LIKE(`code_module`, '^[A-Z]{3}$')
),

validity_consistency AS (
  SELECT 
    'ftw-week-07.03-mart.dim_course' as table_name,
    'Validity' as dimension,
    'course_key should match code_module' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_course`
  WHERE `course_key` != `code_module`
)

-- =====================================================
-- UNION ALL RESULTS
-- =====================================================
SELECT * FROM completeness_course_key_null
UNION ALL
SELECT * FROM completeness_code_module_null
UNION ALL
SELECT * FROM completeness_course_key_empty
UNION ALL
SELECT * FROM completeness_code_module_empty
UNION ALL
SELECT * FROM uniqueness_course_key
UNION ALL
SELECT * FROM uniqueness_code_module
UNION ALL
SELECT * FROM validity_course_key_format
UNION ALL
SELECT * FROM validity_code_module_format
UNION ALL
SELECT * FROM validity_consistency
ORDER BY dimension, check_name;