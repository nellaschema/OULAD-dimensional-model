%sql
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.fact_assessments
USING DELTA
AS

SELECT
-- Grain: one row per student assessment submission
SHA2(
CONCAT_WS(
'||',
CAST(sa.id_student AS STRING),
CAST(sa.id_assessment AS STRING)
),
256
) AS assessment_submission_key,

ds.student_key,

dd.demographics_key,
CURRENT_TIMESTAMP() AS mart_load_timestamp,
CURRENT_DATE() AS mart_load_date,

dc.course_key,
dmp.module_presentation_key,

CAST(sa.date_submitted AS STRING) AS submission_date_key,

CASE
WHEN a.assessment_date IS NULL THEN NULL
ELSE CAST(a.assessment_date AS STRING)
END AS due_date_key,

CAST(a.id_assessment AS BIGINT) AS id_assessment,
a.assessment_type,
CAST(a.weight AS DECIMAL(5,2)) AS assessment_weight,
CAST(sa.is_banked AS BOOLEAN) AS is_banked,
CAST(sa.score AS DECIMAL(5,2)) AS score

FROM `ftw-week-07`.`02-clean`.student_assessment_clean AS sa

INNER JOIN `ftw-week-07`.`02-clean`.assessments_clean AS a
ON sa.id_assessment = a.id_assessment

INNER JOIN `ftw-week-07`.`02-clean`.student_info_clean AS si
ON sa.id_student = si.id_student
AND a.code_module = si.code_module
AND a.code_presentation = si.code_presentation

LEFT JOIN `ftw-week-07`.`03-mart`.dim_student AS ds
ON sa.id_student = ds.id_student

LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics AS dd
ON COALESCE(si.gender, 'UNKNOWN') = dd.gender
AND COALESCE(si.region, 'UNKNOWN') = dd.region
AND COALESCE(si.highest_education, 'UNKNOWN') = dd.highest_education
AND COALESCE(si.imd_band, 'UNKNOWN') = dd.imd_band
AND COALESCE(si.age_band, 'UNKNOWN') = dd.age_band
AND COALESCE(si.disability, 'UNKNOWN') = dd.disability

LEFT JOIN `ftw-week-07`.`03-mart`.dim_course AS dc
ON a.code_module = dc.code_module

LEFT JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS dmp
ON a.code_module = dmp.code_module
AND a.code_presentation = dmp.code_presentation;