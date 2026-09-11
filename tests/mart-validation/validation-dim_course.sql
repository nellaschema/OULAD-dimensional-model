-- =====================================================
-- COMPREHENSIVE DATA QUALITY VALIDATION 
-- FOR fact_assessments
-- =====================================================
-- This SQL performs validation across 4 dimensions:
-- 1. Completeness (NULL checks for required columns)
-- 2. Uniqueness (Primary key validation)
-- 3. Validity (Business rules and data ranges)
-- 4. Referential Integrity (Foreign key validation)
-- =====================================================

WITH total_count AS (
  SELECT COUNT(*) as total_rows FROM `ftw-week-07`.`03-mart`.`fact_assessments`
),

-- =====================================================
-- 1. COMPLETENESS CHECKS
-- =====================================================

completeness_assessment_submission_key AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'assessment_submission_key should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `assessment_submission_key` IS NULL
),

completeness_student_key AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'student_key should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `student_key` IS NULL
),

completeness_course_key AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'course_key should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `course_key` IS NULL
),

completeness_id_assessment AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'id_assessment should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `id_assessment` IS NULL
),

completeness_assessment_type AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'assessment_type should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `assessment_type` IS NULL
),

completeness_assessment_weight AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Completeness' as dimension,
    'assessment_weight should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `assessment_weight` IS NULL
),

-- Note: score can be NULL for unsubmitted assessments (0.10% NULL rate is acceptable)

-- =====================================================
-- 2. UNIQUENESS CHECKS
-- =====================================================

uniqueness_primary_key AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Uniqueness' as dimension,
    'assessment_submission_key should be unique (primary key)' as check_name,
    COUNT(*) - COUNT(DISTINCT `assessment_submission_key`) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `assessment_submission_key`)) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN COUNT(*) - COUNT(DISTINCT `assessment_submission_key`) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
),

-- =====================================================
-- 3. VALIDITY CHECKS
-- =====================================================

validity_assessment_type AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Validity' as dimension,
    'assessment_type should be TMA, CMA, or Exam' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `assessment_type` IS NOT NULL 
    AND `assessment_type` NOT IN ('TMA', 'CMA', 'Exam')
),

validity_score_range AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Validity' as dimension,
    'score should be between 0 and 100' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `score` IS NOT NULL 
    AND (`score` < 0 OR `score` > 100)
),

validity_weight_range AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Validity' as dimension,
    'assessment_weight should be between 0 and 100' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `assessment_weight` IS NOT NULL 
    AND (`assessment_weight` < 0 OR `assessment_weight` > 100)
),

validity_is_banked AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Validity' as dimension,
    'is_banked should not be NULL' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `is_banked` IS NULL
),

-- =====================================================
-- 4. REFERENTIAL INTEGRITY CHECKS
-- =====================================================

referential_integrity_course AS (
  SELECT 
    'ftw-week-07.03-mart.fact_assessments' as table_name,
    'Referential Integrity' as dimension,
    'fact_assessments.course_key → dim_course.course_key' as check_name,
    COUNT(*) as failed_rows,
    (SELECT total_rows FROM total_count) as total_rows,
    ROUND((COUNT(*) * 100.0) / (SELECT total_rows FROM total_count), 2) as failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
  WHERE f.`course_key` IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM `ftw-week-07`.`03-mart`.`dim_course` d
      WHERE d.`course_key` = f.`course_key`
    )
)

-- =====================================================
-- UNION ALL RESULTS
-- =====================================================
SELECT * FROM completeness_assessment_submission_key
UNION ALL SELECT * FROM completeness_student_key
UNION ALL SELECT * FROM completeness_course_key
UNION ALL SELECT * FROM completeness_id_assessment
UNION ALL SELECT * FROM completeness_assessment_type
UNION ALL SELECT * FROM completeness_assessment_weight
UNION ALL SELECT * FROM uniqueness_primary_key
UNION ALL SELECT * FROM validity_assessment_type
UNION ALL SELECT * FROM validity_score_range
UNION ALL SELECT * FROM validity_weight_range
UNION ALL SELECT * FROM validity_is_banked
UNION ALL SELECT * FROM referential_integrity_course
ORDER BY dimension, check_name;