CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.dim_demographics
USING DELTA
AS
SELECT
  CAST(row_number() OVER (ORDER BY gender, region, highest_education, imd_band, age_band, disability) AS STRING) AS demographics_key,
  gender,
  region,
  highest_education,
  imd_band,
  age_band,
  disability
FROM (
  SELECT DISTINCT gender, region, highest_education, imd_band, age_band, disability
  FROM `ftw-week-07`.`02-clean`.student_info_clean
);