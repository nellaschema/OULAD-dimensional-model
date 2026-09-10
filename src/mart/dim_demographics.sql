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
COALESCE(disability, 'UNKNOWN')
),
256
) AS demographics_key,

COALESCE(gender, 'UNKNOWN') AS gender,
COALESCE(region, 'UNKNOWN') AS region,
COALESCE(highest_education, 'UNKNOWN') AS highest_education,
COALESCE(imd_band, 'UNKNOWN') AS imd_band,
COALESCE(age_band, 'UNKNOWN') AS age_band,
COALESCE(disability, 'UNKNOWN') AS disability,

CURRENT_TIMESTAMP() AS mart_load_timestamp,
CURRENT_DATE() AS mart_load_date
FROM `ftw-week-07`.`02-clean`.student_info_clean