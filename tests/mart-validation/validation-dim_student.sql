-- =====================================================================
-- DATA QUALITY VALIDATION FOR DIM_STUDENT
-- Validates: Completeness, Uniqueness, Validity, Referential Integrity
-- Tolerance: 0.20% for Completeness/Validity, 0 for Uniqueness/RI
-- =====================================================================

-- COMPLETENESS CHECKS
WITH completeness_checks AS (
  SELECT 
    'dim_student' as table_name,
    'Completeness' as dimension,
    'student_key NOT NULL' as check_name,
    COUNT(*) FILTER (WHERE `student_key` IS NULL) as failed_rows,
    COUNT(*) as total_rows,
    ROUND((COUNT(*) FILTER (WHERE `student_key` IS NULL) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `student_key` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
  
  UNION ALL
  
  SELECT 
    'dim_student' as table_name,
    'Completeness' as dimension,
    'id_student NOT NULL' as check_name,
    COUNT(*) FILTER (WHERE `id_student` IS NULL) as failed_rows,
    COUNT(*) as total_rows,
    ROUND((COUNT(*) FILTER (WHERE `id_student` IS NULL) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `id_student` IS NULL) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
),

-- UNIQUENESS CHECKS
uniqueness_checks AS (
  SELECT 
    'dim_student' as table_name,
    'Uniqueness' as dimension,
    'student_key Uniqueness' as check_name,
    (COUNT(*) - COUNT(DISTINCT `student_key`)) as failed_rows,
    COUNT(*) as total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `student_key`)) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN (COUNT(*) - COUNT(DISTINCT `student_key`)) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
  
  UNION ALL
  
  SELECT 
    'dim_student' as table_name,
    'Uniqueness' as dimension,
    'id_student Uniqueness' as check_name,
    (COUNT(*) - COUNT(DISTINCT `id_student`)) as failed_rows,
    COUNT(*) as total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `id_student`)) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN (COUNT(*) - COUNT(DISTINCT `id_student`)) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
),

-- VALIDITY CHECKS
validity_checks AS (
  SELECT 
    'dim_student' as table_name,
    'Validity' as dimension,
    'id_student Positive Value' as check_name,
    COUNT(*) FILTER (WHERE `id_student` <= 0) as failed_rows,
    COUNT(*) as total_rows,
    ROUND((COUNT(*) FILTER (WHERE `id_student` <= 0) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE `id_student` <= 0) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
  
  UNION ALL
  
  SELECT 
    'dim_student' as table_name,
    'Validity' as dimension,
    'student_key Matches id_student' as check_name,
    COUNT(*) FILTER (WHERE CAST(`student_key` AS INT) != `id_student`) as failed_rows,
    COUNT(*) as total_rows,
    ROUND((COUNT(*) FILTER (WHERE CAST(`student_key` AS INT) != `id_student`) * 100.0) / COUNT(*), 2) as failure_rate,
    CASE 
      WHEN ROUND((COUNT(*) FILTER (WHERE CAST(`student_key` AS INT) != `id_student`) * 100.0) / COUNT(*), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM `ftw-week-07`.`03-mart`.`dim_student`
),

-- REFERENTIAL INTEGRITY: FACT_ASSESSMENTS → DIM_STUDENT
ref_int_assessments AS (
  SELECT COUNT(*) as orphan_count
  FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
  WHERE f.`student_key` IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 
      FROM `ftw-week-07`.`03-mart`.`dim_student` d
      WHERE d.`student_key` = f.`student_key`
    )
),
total_assessments AS (
  SELECT COUNT(*) as total_count
  FROM `ftw-week-07`.`03-mart`.`fact_assessments`
  WHERE `student_key` IS NOT NULL
),
referential_integrity_assessments AS (
  SELECT 
    'dim_student' as table_name,
    'Referential Integrity' as dimension,
    'FACT_ASSESSMENTS → DIM_STUDENT FK Check' as check_name,
    a.orphan_count as failed_rows,
    ta.total_count as total_rows,
    ROUND((a.orphan_count * 100.0) / ta.total_count, 2) as failure_rate,
    CASE 
      WHEN a.orphan_count = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM ref_int_assessments a, total_assessments ta
),

-- REFERENTIAL INTEGRITY: FACT_VLE_INTERACTIONS → DIM_STUDENT
ref_int_vle AS (
  SELECT COUNT(*) as orphan_count
  FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions` f
  WHERE f.`student_key` IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 
      FROM `ftw-week-07`.`03-mart`.`dim_student` d
      WHERE d.`student_key` = f.`student_key`
    )
),
total_vle AS (
  SELECT COUNT(*) as total_count
  FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions`
  WHERE `student_key` IS NOT NULL
),
referential_integrity_vle AS (
  SELECT 
    'dim_student' as table_name,
    'Referential Integrity' as dimension,
    'FACT_VLE_INTERACTIONS → DIM_STUDENT FK Check' as check_name,
    v.orphan_count as failed_rows,
    tv.total_count as total_rows,
    ROUND((v.orphan_count * 100.0) / tv.total_count, 2) as failure_rate,
    CASE 
      WHEN v.orphan_count = 0 THEN 'PASS'
      ELSE 'FAIL'
    END as status
  FROM ref_int_vle v, total_vle tv
)

-- COMBINE ALL RESULTS
SELECT table_name, dimension, check_name, failed_rows, total_rows, failure_rate, status
FROM completeness_checks
UNION ALL
SELECT table_name, dimension, check_name, failed_rows, total_rows, failure_rate, status
FROM uniqueness_checks
UNION ALL
SELECT table_name, dimension, check_name, failed_rows, total_rows, failure_rate, status
FROM validity_checks
UNION ALL
SELECT table_name, dimension, check_name, failed_rows, total_rows, failure_rate, status
FROM referential_integrity_assessments
UNION ALL
SELECT table_name, dimension, check_name, failed_rows, total_rows, failure_rate, status
FROM referential_integrity_vle
ORDER BY 
  CASE dimension
    WHEN 'Completeness' THEN 1
    WHEN 'Uniqueness' THEN 2
    WHEN 'Validity' THEN 3
    WHEN 'Referential Integrity' THEN 4
  END,
  check_name;