-- ============================================================================
-- COMPLETE DATA QUALITY VALIDATION FOR fact_assessments
-- ============================================================================
-- This script performs comprehensive DQ validation across 4 dimensions:
-- 1. Completeness
-- 2. Uniqueness
-- 3. Validity
-- 4. Referential Integrity
-- 
-- Tolerance Threshold: 0.20% (failure_rate <= 0.20 = PASS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. COMPLETENESS CHECKS
-- ----------------------------------------------------------------------------
WITH total AS (
    SELECT COUNT(*) as total_rows
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
),
completeness_checks AS (
    SELECT
        'assessment_submission_key' as column_name,
        'Primary Key' as column_category,
        COUNT(*) as failed_rows,
        (SELECT total_rows FROM total) as total_rows
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `assessment_submission_key` IS NULL
    
    UNION ALL
    
    SELECT 'student_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `student_key` IS NULL
    
    UNION ALL
    
    SELECT 'demographics_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `demographics_key` IS NULL
    
    UNION ALL
    
    SELECT 'course_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `course_key` IS NULL
    
    UNION ALL
    
    SELECT 'module_presentation_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `module_presentation_key` IS NULL
    
    UNION ALL
    
    SELECT 'submission_date_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `submission_date_key` IS NULL
    
    UNION ALL
    
    SELECT 'due_date_key', 'Foreign Key', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `due_date_key` IS NULL
    
    UNION ALL
    
    SELECT 'id_assessment', 'Required Attribute', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `id_assessment` IS NULL
    
    UNION ALL
    
    SELECT 'assessment_type', 'Required Attribute', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `assessment_type` IS NULL
    
    UNION ALL
    
    SELECT 'assessment_weight', 'Required Attribute', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `assessment_weight` IS NULL
    
    UNION ALL
    
    SELECT 'is_banked', 'Required Attribute', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `is_banked` IS NULL
    
    UNION ALL
    
    SELECT 'score', 'Measure', COUNT(*), (SELECT total_rows FROM total)
    FROM `ftw-week-07`.`03-mart`.`fact_assessments`
    WHERE `score` IS NULL
)
SELECT
    '1. COMPLETENESS' as dq_dimension,
    column_category,
    column_name,
    'NULL Check' as validation_rule,
    failed_rows,
    total_rows,
    ROUND((failed_rows * 100.0 / total_rows), 4) as failure_rate,
    CASE
        WHEN (failed_rows * 100.0 / total_rows) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM completeness_checks

UNION ALL

-- ----------------------------------------------------------------------------
-- 2. UNIQUENESS CHECKS
-- ----------------------------------------------------------------------------
SELECT
    '2. UNIQUENESS' as dq_dimension,
    'Primary Key' as column_category,
    'assessment_submission_key' as column_name,
    'Duplicate Check' as validation_rule,
    COALESCE(dup.duplicate_count, 0) as failed_rows,
    total.total_rows,
    ROUND((COALESCE(dup.duplicate_count, 0) * 100.0 / total.total_rows), 4) as failure_rate,
    CASE
        WHEN (COALESCE(dup.duplicate_count, 0) * 100.0 / total.total_rows) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM (SELECT COUNT(*) as total_rows FROM `ftw-week-07`.`03-mart`.`fact_assessments`) total
LEFT JOIN (
    SELECT COUNT(*) as duplicate_count
    FROM (
        SELECT `assessment_submission_key`
        FROM `ftw-week-07`.`03-mart`.`fact_assessments`
        WHERE `assessment_submission_key` IS NOT NULL
        GROUP BY `assessment_submission_key`
        HAVING COUNT(*) > 1
    ) dups
) dup ON 1=1

UNION ALL

-- ----------------------------------------------------------------------------
-- 3. VALIDITY CHECKS - Data Type & Range
-- ----------------------------------------------------------------------------
SELECT
    '3. VALIDITY' as dq_dimension,
    'Value Range' as column_category,
    'score' as column_name,
    'Range (0-100)' as validation_rule,
    COUNT(*) as failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`) as total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4) as failure_rate,
    CASE
        WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `score` IS NOT NULL AND (`score` < 0 OR `score` > 100)

UNION ALL

SELECT
    '3. VALIDITY', 'Value Range', 'assessment_weight', 'Range (0-100)',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `assessment_weight` IS NOT NULL AND (`assessment_weight` < 0 OR `assessment_weight` > 100)

UNION ALL

SELECT
    '3. VALIDITY', 'Value Range', 'id_assessment', 'Positive Integer',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `id_assessment` IS NOT NULL AND `id_assessment` <= 0

UNION ALL

SELECT
    '3. VALIDITY', 'Format', 'submission_date_key', 'Numeric String',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `submission_date_key` IS NOT NULL AND `submission_date_key` NOT RLIKE '^-?[0-9]+$'

UNION ALL

SELECT
    '3. VALIDITY', 'Format', 'due_date_key', 'Numeric String',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `due_date_key` IS NOT NULL AND `due_date_key` NOT RLIKE '^-?[0-9]+$'

UNION ALL

-- ----------------------------------------------------------------------------
-- 3. VALIDITY CHECKS - Categorical
-- ----------------------------------------------------------------------------
SELECT
    '3. VALIDITY', 'Categorical', 'assessment_type', 'Valid Types (CMA, Exam, TMA)',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `assessment_type` IS NOT NULL AND `assessment_type` NOT IN ('CMA', 'Exam', 'TMA')

UNION ALL

SELECT
    '3. VALIDITY', 'Categorical', 'is_banked', 'Valid Boolean',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments`
WHERE `is_banked` IS NOT NULL AND `is_banked` NOT IN (true, false)

UNION ALL

-- ----------------------------------------------------------------------------
-- 4. REFERENTIAL INTEGRITY CHECKS
-- ----------------------------------------------------------------------------
SELECT
    '4. REFERENTIAL INTEGRITY' as dq_dimension,
    'Foreign Key' as column_category,
    'student_key' as column_name,
    'FK to dim_student' as validation_rule,
    COUNT(*) as failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`) as total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4) as failure_rate,
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END as status
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_student` d ON f.`student_key` = d.`student_key`
WHERE f.`student_key` IS NOT NULL AND d.`student_key` IS NULL

UNION ALL

SELECT
    '4. REFERENTIAL INTEGRITY', 'Foreign Key', 'demographics_key', 'FK to dim_demographics',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_demographics` d ON f.`demographics_key` = d.`demographics_key`
WHERE f.`demographics_key` IS NOT NULL AND d.`demographics_key` IS NULL

UNION ALL

SELECT
    '4. REFERENTIAL INTEGRITY', 'Foreign Key', 'course_key', 'FK to dim_course',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_course` d ON f.`course_key` = d.`course_key`
WHERE f.`course_key` IS NOT NULL AND d.`course_key` IS NULL

UNION ALL

SELECT
    '4. REFERENTIAL INTEGRITY', 'Foreign Key', 'module_presentation_key', 'FK to dim_module_presentation',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_module_presentation` d ON f.`module_presentation_key` = d.`module_presentation_key`
WHERE f.`module_presentation_key` IS NOT NULL AND d.`module_presentation_key` IS NULL

UNION ALL

SELECT
    '4. REFERENTIAL INTEGRITY', 'Foreign Key', 'submission_date_key', 'FK to dim_date',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_date` d ON f.`submission_date_key` = d.`date_key`
WHERE f.`submission_date_key` IS NOT NULL AND d.`date_key` IS NULL

UNION ALL

SELECT
    '4. REFERENTIAL INTEGRITY', 'Foreign Key', 'due_date_key', 'FK to dim_date',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`),
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 4),
    CASE WHEN (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)) <= 0.20 THEN 'PASS' ELSE 'FAIL' END
FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
LEFT JOIN `ftw-week-07`.`03-mart`.`dim_date` d ON f.`due_date_key` = d.`date_key`
WHERE f.`due_date_key` IS NOT NULL AND d.`date_key` IS NULL

-- ----------------------------------------------------------------------------
-- ORDER RESULTS
-- ----------------------------------------------------------------------------
ORDER BY 
    CASE dq_dimension
        WHEN '1. COMPLETENESS' THEN 1
        WHEN '2. UNIQUENESS' THEN 2
        WHEN '3. VALIDITY' THEN 3
        WHEN '4. REFERENTIAL INTEGRITY' THEN 4
    END,
    column_category,
    column_name;