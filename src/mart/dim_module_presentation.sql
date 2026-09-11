-- ORIGINAL TEAM QUERY: retained for contribution history; dbt model is models/mart/dim_module_presentation.sql.
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
USING DELTA
AS
SELECT
  concat_ws('-', code_module, code_presentation) AS module_presentation_key,
  code_module AS course_key,
  code_module,
  code_presentation,
  module_presentation_length
FROM `ftw-week-07`.`02-clean`.courses_clean;
