CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
USING DELTA
AS
SELECT
  concat_ws('-', CAST(sv.id_student AS STRING), CAST(sv.id_site AS STRING), CAST(sv.activity_date AS STRING)) AS vle_interaction_key,
  ds.student_key,
  dd.demographics_key,
  CAST(sv.activity_date AS STRING) AS activity_date_id,
  dc.course_key,
  dmp.module_presentation_key,
  sv.id_site,
  v.activity_type,
  sv.sum_click
FROM `ftw-week-07`.`02-clean`.student_vle_clean sv
JOIN `ftw-week-07`.`02-clean`.vle_clean v
  ON sv.id_site = v.id_site
 AND sv.code_module = v.code_module
 AND sv.code_presentation = v.code_presentation
JOIN `ftw-week-07`.`02-clean`.student_info_clean si
  ON sv.id_student = si.id_student
 AND sv.code_module = si.code_module
 AND sv.code_presentation = si.code_presentation
LEFT JOIN `ftw-week-07`.`03-mart`.dim_student ds
  ON sv.id_student = ds.id_student
LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics dd
  ON si.gender = dd.gender
 AND si.region = dd.region
 AND si.highest_education = dd.highest_education
 AND si.imd_band = dd.imd_band
 AND si.age_band = dd.age_band
 AND si.disability = dd.disability
LEFT JOIN `ftw-week-07`.`03-mart`.dim_course dc
  ON sv.code_module = dc.code_module
LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation dmp
  ON sv.code_module = dmp.code_module
 AND sv.code_presentation = dmp.code_presentation;