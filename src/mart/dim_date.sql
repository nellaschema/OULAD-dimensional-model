-- ORIGINAL TEAM QUERY: retained for contribution history; dbt model is models/mart/dim_date.sql.
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_date
USING DELTA
AS
WITH date_range AS (
  SELECT MIN(day_offset) AS min_day, MAX(day_offset) AS max_day
  FROM (
    SELECT activity_date AS day_offset FROM `ftw-week-07`.`02-clean`.student_vle_clean
    UNION ALL
    SELECT date_submitted AS day_offset FROM `ftw-week-07`.`02-clean`.student_assessment_clean
    UNION ALL
    SELECT assessment_date AS day_offset FROM `ftw-week-07`.`02-clean`.assessments_clean WHERE assessment_date IS NOT NULL
  )
),
days AS (
  SELECT explode(sequence(min_day, max_day)) AS relative_day
  FROM date_range
)
SELECT
  CAST(relative_day AS STRING) AS date_key,
  CAST(FLOOR(relative_day / 7) AS INT) AS relative_week,
  CAST(relative_day AS INT) AS relative_day,
  CASE
    WHEN relative_day < 0 THEN 'Pre-course'
    ELSE CONCAT('Week ', CAST(FLOOR(relative_day / 7) + 1 AS STRING))
  END AS course_phase
FROM days;
