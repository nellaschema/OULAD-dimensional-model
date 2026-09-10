-----  dim_student
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_student
USING DELTA
AS
SELECT
  CAST(id_student AS STRING) AS student_key,
  id_student
FROM (
  SELECT DISTINCT id_student
  FROM `ftw-week-07`.`02-clean`.student_info_clean
);