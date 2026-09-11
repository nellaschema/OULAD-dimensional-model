-- ORIGINAL TEAM QUERY: retained as supplemental ad hoc checks.
-- The authoritative dbt tests are in models/mart/schema.yml and tests/dbt/.
-- 1. Duplicate assessment business keys
SELECT
    student_key,
    id_assessment,
    COUNT(*) AS record_count
FROM `ftw-week-07`.`03-mart`.fact_assessments
GROUP BY student_key, id_assessment
HAVING COUNT(*) > 1;

-- 2. Missing foreign keys in fact_assessments
SELECT *
FROM `ftw-week-07`.`03-mart`.fact_assessments
WHERE student_key IS NULL
   OR demographics_key IS NULL
   OR course_key IS NULL
   OR module_presentation_key IS NULL;

-- 3. Duplicate VLE business keys
SELECT
    student_key,
    id_site,
    activity_date_id,
    COUNT(*) AS record_count
FROM `ftw-week-07`.`03-mart`.fact_vle_interactions
GROUP BY student_key, id_site, activity_date_id
HAVING COUNT(*) > 1;

-- 4. Missing foreign keys in fact_vle_interactions
SELECT *
FROM `ftw-week-07`.`03-mart`.fact_vle_interactions
WHERE student_key IS NULL
   OR demographics_key IS NULL
   OR course_key IS NULL
   OR module_presentation_key IS NULL;

-- 5. Invalid assessment scores
SELECT *
FROM `ftw-week-07`.`03-mart`.fact_assessments
WHERE score < 0 OR score > 100;
