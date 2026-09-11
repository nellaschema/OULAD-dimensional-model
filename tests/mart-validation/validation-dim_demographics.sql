-- =====================================================
-- DATA QUALITY VALIDATION: dim_demographics
-- =====================================================

WITH 

-- 1. COMPLETENESS CHECKS
completeness_checks AS (
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'demographics_key is not null' AS check_name,
    COUNT(*) - COUNT(`demographics_key`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`demographics_key`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`demographics_key`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'gender is not null' AS check_name,
    COUNT(*) - COUNT(`gender`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`gender`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`gender`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'region is not null' AS check_name,
    COUNT(*) - COUNT(`region`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`region`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`region`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'highest_education is not null' AS check_name,
    COUNT(*) - COUNT(`highest_education`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`highest_education`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`highest_education`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'age_band is not null' AS check_name,
    COUNT(*) - COUNT(`age_band`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`age_band`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`age_band`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Completeness' AS dimension,
    'disability is not null' AS check_name,
    COUNT(*) - COUNT(`disability`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(`disability`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN ROUND(((COUNT(*) - COUNT(`disability`)) * 100.0 / COUNT(*)), 2) <= 0.20 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
),

-- 2. UNIQUENESS CHECK
uniqueness_check AS (
  SELECT 
    'dim_demographics' AS table_name,
    'Uniqueness' AS dimension,
    'demographics_key is unique (primary key)' AS check_name,
    COUNT(*) - COUNT(DISTINCT `demographics_key`) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(((COUNT(*) - COUNT(DISTINCT `demographics_key`)) * 100.0 / COUNT(*)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) - COUNT(DISTINCT `demographics_key`) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
),

-- 3. VALIDITY CHECKS
validity_checks AS (
  SELECT 
    'dim_demographics' AS table_name,
    'Validity' AS dimension,
    'gender contains valid values (M, F)' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  WHERE `gender` NOT IN ('M', 'F')
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Validity' AS dimension,
    'disability contains valid values (Y, N)' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  WHERE `disability` NOT IN ('Y', 'N')
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Validity' AS dimension,
    'age_band contains valid values (0-35, 35-55, 55<=)' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  WHERE `age_band` NOT IN ('0-35', '35-55', '55<=')
  
  UNION ALL
  
  SELECT 
    'dim_demographics' AS table_name,
    'Validity' AS dimension,
    'imd_band contains valid values (decile bands or ?)' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`dim_demographics`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`dim_demographics`
  WHERE `imd_band` NOT IN ('0-10%', '10-20', '20-30%', '30-40%', '40-50%', '50-60%', '60-70%', '70-80%', '80-90%', '90-100%', '?')
),

-- 4. REFERENTIAL INTEGRITY CHECKS
referential_integrity_checks AS (
  -- Check 1: fact_assessments -> dim_demographics
  SELECT 
    'dim_demographics' AS table_name,
    'Referential Integrity' AS dimension,
    'fact_assessments.demographics_key -> dim_demographics.demographics_key' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_assessments`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`fact_assessments` f
  WHERE NOT EXISTS (
    SELECT 1 
    FROM `ftw-week-07`.`03-mart`.`dim_demographics` d
    WHERE d.`demographics_key` = f.`demographics_key`
  )
  
  UNION ALL
  
  -- Check 2: fact_vle_interactions -> dim_demographics
  SELECT 
    'dim_demographics' AS table_name,
    'Referential Integrity' AS dimension,
    'fact_vle_interactions.demographics_key -> dim_demographics.demographics_key' AS check_name,
    COUNT(*) AS failed_rows,
    (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions`) AS total_rows,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions`)), 2) AS failure_rate,
    CASE 
      WHEN COUNT(*) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END AS status
  FROM `ftw-week-07`.`03-mart`.`fact_vle_interactions` f
  WHERE NOT EXISTS (
    SELECT 1 
    FROM `ftw-week-07`.`03-mart`.`dim_demographics` d
    WHERE d.`demographics_key` = f.`demographics_key`
  )
)

-- FINAL RESULT: Combine all checks
SELECT * FROM completeness_checks
UNION ALL
SELECT * FROM uniqueness_check
UNION ALL
SELECT * FROM validity_checks
UNION ALL
SELECT * FROM referential_integrity_checks
ORDER BY 
  CASE dimension
    WHEN 'Completeness' THEN 1
    WHEN 'Uniqueness' THEN 2
    WHEN 'Validity' THEN 3
    WHEN 'Referential Integrity' THEN 4
  END,
  check_name;