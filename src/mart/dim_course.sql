-- ORIGINAL TEAM QUERY: retained for contribution history; dbt model is models/mart/dim_course.sql.
-----  dim_course
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_course
USING DELTA
AS
SELECT
  code_module AS course_key,
  code_module
FROM (
  SELECT DISTINCT code_module
  FROM `ftw-week-07`.`02-clean`.courses_clean
);
