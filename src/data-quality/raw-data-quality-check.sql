%sql

-- OULAD Raw/Bronze Data Quality Checks
-- Grain: One row per quality check and dataset.
-- Result: 0 failed_count means the check passed.

WITH quality_checks AS (

  -- 1. Courses: required keys and valid duration
  SELECT
    'courses' AS dataset_name,
    'Required fields and valid course length' AS check_name,
    'COMPLETENESS_VALIDITY' AS quality_dimension,
    COUNT(*) AS total_count,
    COUNT_IF(
      code_module IS NULL
      OR TRIM(code_module) = ''
      OR code_presentation IS NULL
      OR TRIM(code_presentation) = ''
      OR module_presentation_length IS NULL
      OR module_presentation_length <= 0
    ) AS failed_count,
    'CRITICAL' AS severity
  FROM `ftw-week-07`.`01-raw`.courses

  UNION ALL

  -- 2. Courses: unique business key
  SELECT
    'courses',
    'Course business key is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation)),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.courses

  UNION ALL

  -- 3. Assessments: required fields and valid values
  SELECT
    'assessments',
    'Required fields and valid assessment values',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      code_module IS NULL
      OR code_presentation IS NULL
      OR id_assessment IS NULL
      OR assessment_type IS NULL
      OR TRIM(assessment_type) = ''
      OR weight IS NULL
      OR weight < 0
      OR weight > 100
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.assessments

  UNION ALL

  -- 4. Assessments: unique assessment ID
  SELECT
    'assessments',
    'Assessment ID is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT id_assessment),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.assessments

  UNION ALL

  -- 5. Student assessment: required keys and valid score range
  SELECT
    'student_assessment',
    'Required keys and valid score range',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR id_assessment IS NULL
      OR score IS NOT NULL AND (score < 0 OR score > 100)
      OR is_banked IS NOT NULL AND is_banked NOT IN (0, 1)
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_assessment

  UNION ALL

  -- 6. Student assessment: unique student-assessment grain
  SELECT
    'student_assessment',
    'Student-assessment business key is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(id_student, id_assessment)),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_assessment

  UNION ALL

  -- 7. Student info: required keys and valid domains
  SELECT
    'student_info',
    'Required keys and valid domain values',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      code_module IS NULL
      OR code_presentation IS NULL
      OR id_student IS NULL
      OR gender IS NULL
      OR gender NOT IN ('F', 'M')
      OR disability IS NULL
      OR disability NOT IN ('Y', 'N')
      OR final_result IS NULL
      OR final_result NOT IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_info

  UNION ALL

  -- 8. Student info: unique enrollment grain
  SELECT
    'student_info',
    'Student enrollment business key is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation, id_student)),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_info

  UNION ALL

  -- 9. Student registration: required keys and valid dates
  SELECT
    'student_registration',
    'Required keys and valid registration dates',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR code_module IS NULL
      OR code_presentation IS NULL
      OR date_registration IS NULL
      OR (
        date_unregistration IS NOT NULL
        AND date_unregistration < date_registration
      )
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_registration

  UNION ALL

  -- 10. Student registration: unique registration grain
  SELECT
    'student_registration',
    'Registration business key is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_student,
      code_module,
      code_presentation
    )),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_registration

  UNION ALL

  -- 11. Student VLE: required keys and valid click counts
  SELECT
    'student_vle',
    'Required keys and valid activity values',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      id_site IS NULL
      OR id_student IS NULL
      OR code_module IS NULL
      OR code_presentation IS NULL
      OR date IS NULL
      OR sum_click IS NULL
      OR sum_click < 0
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_vle

  UNION ALL

  -- 12. Student VLE: unique daily activity grain
  SELECT
    'student_vle',
    'Daily student activity grain is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_site,
      id_student,
      code_module,
      code_presentation,
      date
    )),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.student_vle

  UNION ALL

  -- 13. VLE: required fields and valid week range
  SELECT
    'vle',
    'Required fields and valid week range',
    'COMPLETENESS_VALIDITY',
    COUNT(*),
    COUNT_IF(
      id_site IS NULL
      OR code_module IS NULL
      OR code_presentation IS NULL
      OR activity_type IS NULL
      OR TRIM(activity_type) = ''
      OR (
        week_from IS NOT NULL
        AND week_to IS NOT NULL
        AND week_from > week_to
      )
    ),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.vle

  UNION ALL

  -- 14. VLE: unique site within a course presentation
  SELECT
    'vle',
    'VLE site business key is unique',
    'UNIQUENESS',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_site,
      code_module,
      code_presentation
    )),
    'CRITICAL'
  FROM `ftw-week-07`.`01-raw`.vle
),

classified AS (
  SELECT
    dataset_name,
    check_name,
    quality_dimension,
    total_count,
    failed_count,
    total_count - failed_count AS passed_count,
    CASE
      WHEN total_count = 0 THEN 'FAIL'
      WHEN failed_count > 0 THEN 'FAIL'
      ELSE 'PASS'
    END AS status,
    severity
  FROM quality_checks
)

SELECT
  CURRENT_TIMESTAMP() AS executed_at,
  'BRONZE' AS layer,
  dataset_name,
  check_name,
  quality_dimension,
  total_count,
  failed_count,
  passed_count,
  status,
  severity
FROM classified
ORDER BY
  CASE WHEN status = 'FAIL' THEN 1 ELSE 2 END,
  dataset_name,
  check_name;
