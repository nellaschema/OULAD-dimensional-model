%sql
CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_demographics
USING DELTA
AS
SELECT DISTINCT
SHA2(
CONCAT_WS(
'||',
COALESCE(gender, 'UNKNOWN'),
COALESCE(region, 'UNKNOWN'),
COALESCE(highest_education, 'UNKNOWN'),
COALESCE(imd_band, 'UNKNOWN'),
COALESCE(age_band, 'UNKNOWN'),
COALESCE(disability, 'UNKNOWN'),
COALESCE(final_result, 'UNKNOWN')
),
256
) AS demographics_key,
gender,
region,
highest_education,
imd_band,
age_band,
disability,
final_result
FROM `ftw-week-07`.`02-clean`.student_info_clean;