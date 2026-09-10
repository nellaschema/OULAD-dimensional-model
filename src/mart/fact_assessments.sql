CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.fact_assessments
USING DELTA
AS
SELECT
  concat_ws('-', CAST(sa.id_student AS STRING), CAST(sa.id_assessment AS STRING)) AS assessment_submission_key,
  ds.student_key,
  dd.demographics_key,
  dc.course_key,
  dmp.module_presentation_key,
  CAST(sa.date_submitted AS STRING) AS submission_date_key,
  CAST(a.assessment_date AS STRING) AS due_date_key,
  a.id_assessment,
  a.assessment_type,
  CAST(a.weight AS DECIMAL(5,1)) AS assessment_weight,
  sa.is_banked,
  sa.score
FROM `ftw-week-07`.`02-clean`.student_assessment_clean sa
JOIN `ftw-week-07`.`02-clean`.assessments_clean a
  ON sa.id_assessment = a.id_assessment
JOIN `ftw-week-07`.`02-clean`.student_info_clean si
  ON sa.id_student = si.id_student
 AND a.code_module = si.code_module
 AND a.code_presentation = si.code_presentation
LEFT JOIN `ftw-week-07`.`03-mart`.dim_student ds
  ON sa.id_student = ds.id_student
LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics dd
  ON si.gender = dd.gender
 AND si.region = dd.region
 AND si.highest_education = dd.highest_education
 AND si.imd_band = dd.imd_band
 AND si.age_band = dd.age_band
 AND si.disability = dd.disability
LEFT JOIN `ftw-week-07`.`03-mart`.dim_course dc
  ON a.code_module = dc.code_module
LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation dmp
  ON a.code_module = dmp.code_module
 AND a.code_presentation = dmp.code_presentation;