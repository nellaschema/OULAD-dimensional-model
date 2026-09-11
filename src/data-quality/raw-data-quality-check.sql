%sql

-- OULAD Bronze/Raw Data Quality Checks
-- Raw data is retained; corrections are handled in the Clean/Silver layer.

WITH checks AS (

  SELECT
    'courses' AS dataset_name,
    'Required fields and valid course length' AS check_name,
    COUNT(*) AS total_count,
    COUNT_IF(
      code_module IS NULL OR TRIM(code_module) = ''
      OR code_presentation IS NULL OR TRIM(code_presentation) = ''
      OR module_presentation_length IS NULL
      OR module_presentation_length <= 0
    ) AS failed_count
  FROM `ftw-week-07`.`01-raw`.courses

  UNION ALL

  SELECT
    'courses',
    'Course business key is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(code_module, code_presentation))
  FROM `ftw-week-07`.`01-raw`.courses

  UNION ALL

  SELECT
    'assessments',
    'Required fields and valid weight',
    COUNT(*),
    COUNT_IF(
      code_module IS NULL
      OR code_presentation IS NULL
      OR id_assessment IS NULL
      OR assessment_type IS NULL
      OR weight IS NULL
      OR weight < 0
      OR weight > 100
    )
  FROM `ftw-week-07`.`01-raw`.assessments

  UNION ALL

  SELECT
    'assessments',
    'Assessment ID is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT id_assessment)
  FROM `ftw-week-07`.`01-raw`.assessments

  UNION ALL

  SELECT
    'student_assessment',
    'Required keys and valid score values',
    COUNT(*),
    COUNT_IF(
      id_student IS NULL
      OR id_assessment IS NULL
      OR (score IS NOT NULL AND (score < 0 OR score > 100))
      OR (is_banked IS NOT NULL AND is_banked NOT IN (0, 1))
    )
  FROM `ftw-week-07`.`01-raw`.student_assessment

  UNION ALL

  SELECT
    'student_assessment',
    'Student-assessment business key is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(id_student, id_assessment))
  FROM `ftw-week-07`.`01-raw`.student_assessment

  UNION ALL

  SELECT
    'student_info',
    'Required keys and valid domain values',
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
    )
  FROM `ftw-week-07`.`01-raw`.student_info

  UNION ALL

  SELECT
    'student_info',
    'Student enrollment business key is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      code_module,
      code_presentation,
      id_student
    ))
  FROM `ftw-week-07`.`01-raw`.student_info

  UNION ALL

  SELECT
    'student_registration',
    'Required keys and valid registration dates',
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
    )
  FROM `ftw-week-07`.`01-raw`.student_registration

  UNION ALL

  SELECT
    'student_registration',
    'Registration business key is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_student,
      code_module,
      code_presentation
    ))
  FROM `ftw-week-07`.`01-raw`.student_registration

  UNION ALL

  SELECT
    'student_vle',
    'Required keys and valid click values',
    COUNT(*),
    COUNT_IF(
      id_site IS NULL
      OR id_student IS NULL
      OR code_module IS NULL
      OR code_presentation IS NULL
      OR activity_date IS NULL
      OR sum_click IS NULL
      OR sum_click < 0
    )
  FROM `ftw-week-07`.`01-raw`.student_vle

  UNION ALL

  SELECT
    'student_vle',
    'Daily student activity grain is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_site,
      id_student,
      code_module,
      code_presentation,
      activity_date
    ))
  FROM `ftw-week-07`.`01-raw`.student_vle

  UNION ALL

  SELECT
    'vle',
    'Required fields and valid week range',
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
    )
  FROM `ftw-week-07`.`01-raw`.vle

  UNION ALL

  SELECT
    'vle',
    'VLE site business key is unique',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT STRUCT(
      id_site,
      code_module,
      code_presentation
    ))
  FROM `ftw-week-07`.`01-raw`.vle
)

SELECT
  CURRENT_TIMESTAMP() AS executed_at,
  'BRONZE' AS layer,
  dataset_name,
  check_name,
  total_count,
  failed_count,
  total_count - failed_count AS passed_count,
  CASE
    WHEN total_count = 0 OR failed_count > 0 THEN 'FAIL'
    ELSE 'PASS'
  END AS status
FROM checks
ORDER BY status DESC, dataset_name, check_name;