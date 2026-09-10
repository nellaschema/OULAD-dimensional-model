%sql
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
USING DELTA
AS

SELECT
-- Grain:
-- One row per module + presentation + student + VLE site + activity day
SHA2(
CONCAT_WS(
'||',
sv.code_module,
sv.code_presentation,
CAST(sv.id_student AS STRING),
CAST(sv.id_site AS STRING),
CAST(sv.activity_date AS STRING)
),
256
) AS vle_interaction_key,

ds.student_key,

dd.demographics_key,
CURRENT_TIMESTAMP() AS mart_load_timestamp,
CURRENT_DATE() AS mart_load_date,

CAST(sv.activity_date AS STRING) AS activity_date_id,
dc.course_key,
dmp.module_presentation_key,
CAST(sv.id_site AS BIGINT) AS id_site,
v.activity_type,
CAST(sv.sum_click AS BIGINT) AS sum_click

FROM `ftw-week-07`.`02-clean`.student_vle_clean AS sv

INNER JOIN `ftw-week-07`.`02-clean`.vle_clean AS v
ON sv.id_site = v.id_site
AND sv.code_module = v.code_module
AND sv.code_presentation = v.code_presentation

INNER JOIN `ftw-week-07`.`02-clean`.student_info_clean AS si
ON sv.id_student = si.id_student
AND sv.code_module = si.code_module
AND sv.code_presentation = si.code_presentation

LEFT JOIN `ftw-week-07`.`03-mart`.dim_student AS ds
ON sv.id_student = ds.id_student

LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics AS dd
ON COALESCE(si.gender, 'UNKNOWN') = dd.gender
AND COALESCE(si.region, 'UNKNOWN') = dd.region
AND COALESCE(si.highest_education, 'UNKNOWN') = dd.highest_education
AND COALESCE(si.imd_band, 'UNKNOWN') = dd.imd_band
AND COALESCE(si.age_band, 'UNKNOWN') = dd.age_band
AND COALESCE(si.disability, 'UNKNOWN') = dd.disability

LEFT JOIN `ftw-week-07`.`03-mart`.dim_course AS dc
ON sv.code_module = dc.code_module

LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS dmp
ON sv.code_module = dmp.code_module
AND sv.code_presentation = dmp.code_presentation;