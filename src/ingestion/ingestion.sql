-- Ingest assessments 
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.assessments ( 
    code_module STRING, 
    code_presentation STRING, 
    id_assessment INT, 
    assessment_type STRING, 
    date INT, -- number of days relative to the module presentation start date, we can transform it later in Silver 
    weight DOUBLE -- weight is a decimal percentage contribution of the assessment to the course total 
) USING DELTA; 
 
COPY INTO `ftw-week-07`.`01-raw`.assessments 
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(id_assessment AS INT) AS id_assessment,
        assessment_type,
        TRY_CAST(date AS INT) AS date,
        TRY_CAST(weight AS DOUBLE) AS weight
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/assessments.csv'
)
FILEFORMAT = CSV 
FORMAT_OPTIONS ( 
    'header' = 'true', 
    'inferSchema' = 'false' 
);


-- Ingest courses 
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.courses ( 
    code_module STRING, 
    code_presentation STRING, 
    module_presentation_length INT 
) USING DELTA; 
 
COPY INTO `ftw-week-07`.`01-raw`.courses 
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(module_presentation_length AS INT) AS module_presentation_length
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/courses.csv'
)
FILEFORMAT = CSV 
FORMAT_OPTIONS ( 
    'header' = 'true', 
    'inferSchema' = 'false' 
);


-- Ingest student_assessment  
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_assessment (  
    id_student INT,  
    id_assessment INT,  
    date_submitted INT,  
    is_banked TINYINT, -- indicates whether the assessment score was carried forward from a previous attempt (0 = no, 1 = yes)  
    score DOUBLE  
) USING DELTA;  
  
COPY INTO `ftw-week-07`.`01-raw`.student_assessment  
FROM (
    SELECT  
        TRY_CAST(id_student AS INT) AS id_student,
        TRY_CAST(id_assessment AS INT) AS id_assessment,
        TRY_CAST(date_submitted AS INT) AS date_submitted,
        TRY_CAST(is_banked AS TINYINT) AS is_banked, -- indicates whether the assessment score was carried forward from a previous attempt (0 = no, 1 = yes)
        TRY_CAST(score AS DOUBLE) AS score
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentAssessment.csv'
)
FILEFORMAT = CSV  
FORMAT_OPTIONS (  
    'header' = 'true',  
    'inferSchema' = 'false'  
);


-- Ingest student_info  
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_info (  
    code_module STRING,  
    code_presentation STRING,  
    id_student INT,  
    gender STRING,  
    region STRING,   
    highest_education STRING,   
    imd_band STRING,   
    num_of_prev_attempts INT,   
    studied_credits INT,   
    age_band STRING,   
    disability STRING,   
    final_result STRING  
) USING DELTA;  
  
COPY INTO `ftw-week-07`.`01-raw`.student_info  
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(id_student AS INT) AS id_student,
        gender,
        region,
        highest_education,
        imd_band,
        TRY_CAST(num_of_prev_attempts AS INT) AS num_of_prev_attempts,
        TRY_CAST(studied_credits AS INT) AS studied_credits,
        age_band,
        disability,
        final_result
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentInfo.csv'
)
FILEFORMAT = CSV  
FORMAT_OPTIONS (  
    'header' = 'true',  
    'inferSchema' = 'false'  
);


-- Ingest student_registration  
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_registration (  
    id_student INT,  
    code_module STRING,  
    code_presentation STRING,  
    date_registration INT, -- convert to actual dates in silver  
    date_unregistration INT  
) USING DELTA;  
  
COPY INTO `ftw-week-07`.`01-raw`.student_registration  
FROM (
    SELECT
        TRY_CAST(id_student AS INT) AS id_student,
        code_module,
        code_presentation,
        TRY_CAST(date_registration AS INT) AS date_registration, -- convert to actual dates in silver
        TRY_CAST(date_unregistration AS INT) AS date_unregistration
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentRegistration.csv'
)
FILEFORMAT = CSV  
FORMAT_OPTIONS (  
    'header' = 'true',  
    'inferSchema' = 'false'  
);


-- Ingest student_vle  
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_vle (  
    id_site INT,  
    id_student INT,  
    code_module STRING,  
    code_presentation STRING,  
    date INT, -- number of days relative to the module presentation start date, we can transform it later in Silver  
    sum_click INT  
) USING DELTA;  
  
COPY INTO `ftw-week-07`.`01-raw`.student_vle  
FROM (
    SELECT
        TRY_CAST(id_site AS INT) AS id_site,
        TRY_CAST(id_student AS INT) AS id_student,
        code_module,
        code_presentation,
        TRY_CAST(date AS INT) AS date, -- number of days relative to the module presentation start date, we can transform it later in Silver
        TRY_CAST(sum_click AS INT) AS sum_click
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentVle.csv'
)
FILEFORMAT = CSV  
FORMAT_OPTIONS (  
    'header' = 'true',  
    'inferSchema' = 'false'  
);


-- Ingest vle  
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.vle (  
    id_site INT,  
    code_module STRING,  
    code_presentation STRING,  
    activity_type STRING,  
    week_from INT,  
    week_to INT  
) USING DELTA;  
  
COPY INTO `ftw-week-07`.`01-raw`.vle  
FROM (
    SELECT
        TRY_CAST(id_site AS INT) AS id_site,
        code_module,
        code_presentation,
        activity_type,
        TRY_CAST(week_from AS INT) AS week_from,
        TRY_CAST(week_to AS INT) AS week_to
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/vle.csv'
)
FILEFORMAT = CSV  
FORMAT_OPTIONS (  
    'header' = 'true',  
    'inferSchema' = 'false'  
);