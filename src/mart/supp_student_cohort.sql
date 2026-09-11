-- Supporting Table: Student Cohort
-- ORIGINAL TEAM QUERY: retained for contribution history and not run by the final path.
-- The final cohort model is src/04_analytics/sql/09_learner_outcomes.sql so
-- enrollment outcomes do not become a third core Gold fact.
-- Grain: One row per student enrollment per module presentation
-- Purpose: Track enrollment outcomes (supporting table in mart layer)

CREATE OR REPLACE TABLE `ftw-week-07`.`03-mart`.supp_student_cohort AS

WITH student_enrollments AS (
    SELECT
        -- Source identifiers
        si.id_student,
        si.code_module,
        si.code_presentation,
        
        -- Demographic attributes for dimension join
        si.gender,
        si.region,
        si.highest_education,
        si.imd_band,
        si.age_band,
        si.disability,
        
        -- Outcome measures
        si.final_result,
        si.num_of_prev_attempts,
        si.studied_credits,
        
        -- Registration dates
        sr.date_registration,
        sr.date_unregistration
        
    FROM `ftw-week-07`.`02-clean`.student_info_clean si
    LEFT JOIN `ftw-week-07`.`02-clean`.student_registration_clean sr
        ON si.id_student = sr.id_student
        AND si.code_module = sr.code_module
        AND si.code_presentation = sr.code_presentation
)

SELECT
    -- Surrogate primary key
    MD5(CONCAT(
        COALESCE(CAST(ds.student_key AS STRING), ''),
        COALESCE(CAST(dmp.module_presentation_key AS STRING), '')
    )) AS student_cohort_key,
    
    -- Foreign keys to dimensions
    ds.student_key,
    dmp.module_presentation_key,
    dd.demographics_key,
    
    -- Enrollment outcome measures
    CASE 
        WHEN e.final_result = 'Withdrawn' THEN TRUE
        ELSE FALSE
    END AS is_withdrawn,
    
    e.final_result,
    e.date_registration,
    e.date_unregistration,
    e.studied_credits AS credits,
    e.num_of_prev_attempts AS previous_attempts,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_DATE() AS load_date
    
FROM student_enrollments e

-- Join to dimension tables to get surrogate keys
INNER JOIN `ftw-week-07`.`03-mart`.dim_student ds
    ON e.id_student = ds.id_student
    
INNER JOIN `ftw-week-07`.`03-mart`.dim_module_presentation dmp
    ON e.code_module = dmp.code_module
    AND e.code_presentation = dmp.code_presentation
    
LEFT JOIN `ftw-week-07`.`03-mart`.dim_demographics dd
    ON e.gender = dd.gender
    AND e.region = dd.region
    AND e.highest_education = dd.highest_education
    AND e.imd_band = dd.imd_band
    AND e.age_band = dd.age_band
    AND e.disability = dd.disability;
