%sql
-- Purpose: Clean source rows, normalize domains, and retain only conformed relationships.
-- Grain: One clean row at the original grain of each source entity or event.
-- Explanation: Declare variables needed from the setup notebook.
DECLARE OR REPLACE VARIABLE raw_namespace STRING DEFAULT '`ftw-week-07`.`01-raw`';
DECLARE OR REPLACE VARIABLE clean_namespace STRING DEFAULT '`ftw-week-07`.`02-clean`';

-- clean courses table: normalize module and presentation codes to uppercase for consistent joins
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.courses_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(code_module)) AS code_module,        -- standardize to uppercase for case-insensitive matching
  UPPER(TRIM(code_presentation)) AS code_presentation,
  module_presentation_length
FROM IDENTIFIER(raw_namespace || '.courses')
WHERE code_module IS NOT NULL                      -- ensure required fields are present
  AND TRIM(code_module) <> ''                      -- exclude empty strings
  AND code_presentation IS NOT NULL
  AND TRIM(code_presentation) <> ''
  AND module_presentation_length > 0;              -- only valid course lengths

-- clean assessments table: retain only valid assessments linked to existing courses (referential integrity)
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.assessments_clean')
USING DELTA
AS
SELECT
  assessment.id_assessment,
  UPPER(TRIM(assessment.code_module)) AS code_module,
  UPPER(TRIM(assessment.code_presentation)) AS code_presentation,
  assessment.assessment_type,
  assessment.date AS assessment_date,
  assessment.weight
FROM IDENTIFIER(raw_namespace || '.assessments') AS assessment
INNER JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course  -- inner join ensures only assessments for valid courses
  ON UPPER(TRIM(assessment.code_module)) = course.code_module
  AND UPPER(TRIM(assessment.code_presentation)) = course.code_presentation
WHERE assessment.id_assessment IS NOT NULL
  AND assessment.assessment_type IN ('CMA', 'TMA', 'Exam')  -- only known assessment types
  AND assessment.weight BETWEEN 0 AND 100                   -- weight must be a valid percentage
  AND (assessment.assessment_type = 'Exam' OR assessment.date IS NOT NULL)  -- exams may have null dates, others must not
  AND (assessment.date IS NULL OR assessment.date >= 0); -- exams may have a NULL due-date offset, while existing assessment dates cannot be negative.

-- clean VLE (Virtual Learning Environment) activities: normalize activity types and enforce logical week ranges
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.vle_clean')
USING DELTA
AS
SELECT
  vle.id_site,
  UPPER(TRIM(vle.code_module)) AS code_module,
  UPPER(TRIM(vle.code_presentation)) AS code_presentation,
  LOWER(TRIM(vle.activity_type)) AS activity_type,  -- lowercase for consistent activity type comparison
  vle.week_from,
  vle.week_to
FROM IDENTIFIER(raw_namespace || '.vle') AS vle
INNER JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course  -- only VLE sites for valid courses
  ON UPPER(TRIM(vle.code_module)) = course.code_module
  AND UPPER(TRIM(vle.code_presentation)) = course.code_presentation    
WHERE vle.id_site IS NOT NULL
  AND vle.activity_type IS NOT NULL
  AND TRIM(vle.activity_type) <> ''
  AND LOWER(TRIM(vle.activity_type)) IN (
    'dataplus',
    'dualpane',
    'externalquiz',
    'folder',
    'forumng',
    'glossary',
    'homepage',
    'htmlactivity',
    'oucollaborate',
    'oucontent',
    'ouelluminate',
    'ouwiki',
    'page',
    'questionnaire',
    'quiz',
    'repeatactivity',
    'resource',
    'sharedsubpage',
    'subpage',
    'url'
  )
  AND (
    vle.week_from IS NULL
    OR vle.week_from >= 0
  )
  AND (
    vle.week_to IS NULL
    OR vle.week_to >= 0
  )
  AND (
    vle.week_from IS NULL
    OR vle.week_to IS NULL
    OR vle.week_from <= vle.week_to   -- it validates the accepted OUL activity types, prevents negative week numbers, and retains the logical week order.
  );

-- clean student information: enforce valid domain values and link to existing courses
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.student_info_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(student.code_module)) AS code_module,
  UPPER(TRIM(student.code_presentation)) AS code_presentation,
  student.id_student,
  student.gender,
  TRIM(student.region) AS region,
  TRIM(student.highest_education) AS highest_education,
  NULLIF(TRIM(student.imd_band), '') AS imd_band,  -- convert empty strings to NULL for optional field
  TRIM(student.age_band) AS age_band,
  student.num_of_prev_attempts,
  student.studied_credits,
  student.disability,
  student.final_result
FROM IDENTIFIER(raw_namespace || '.student_info') AS student
INNER JOIN IDENTIFIER(clean_namespace || '.courses_clean') AS course  -- only students enrolled in valid courses
  ON UPPER(TRIM(student.code_module)) = course.code_module
  AND UPPER(TRIM(student.code_presentation)) = course.code_presentation
WHERE student.id_student IS NOT NULL
  AND student.gender IN ('F', 'M')
  AND student.disability IN ('N', 'Y')
  AND student.final_result IN (
    'Withdrawn',
    'Fail',
    'Pass',
    'Distinction'
  )
  AND TRIM(student.age_band) IN (
    '0-35',
    '35-55',
    '55<='
  )
  AND student.num_of_prev_attempts >= 0
  AND student.studied_credits > 0;               

-- clean student registrations: ensure temporal consistency (registration before unregistration) and link to valid students
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.student_registration_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(registration.code_module)) AS code_module,
  UPPER(TRIM(registration.code_presentation)) AS code_presentation,
  registration.id_student,
  registration.date_registration,
  registration.date_unregistration
FROM IDENTIFIER(raw_namespace || '.student_registration') AS registration
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student  -- only registrations for students who exist in student_info_clean
  ON UPPER(TRIM(registration.code_module)) = student.code_module
  AND UPPER(TRIM(registration.code_presentation)) = student.code_presentation
  AND registration.id_student = student.id_student
WHERE registration.date_registration IS NULL      -- allow nulls (missing data)
  OR registration.date_unregistration IS NULL
  OR registration.date_registration <= registration.date_unregistration;  -- logical constraint: registration must come before unregistration

-- clean student assessment submissions: link submissions to valid assessments and students, enforce score ranges
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.student_assessment_clean')
USING DELTA
AS
SELECT
  submission.id_assessment,
  submission.id_student,
  submission.date_submitted,
  CAST(submission.is_banked AS BOOLEAN) AS is_banked,  -- convert integer flag to proper boolean type
  submission.score
FROM IDENTIFIER(raw_namespace || '.student_assessment') AS submission
INNER JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment  -- only submissions for valid assessments
  ON submission.id_assessment = assessment.id_assessment
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student    -- only submissions by valid students in the correct course
  ON assessment.code_module = student.code_module
  AND assessment.code_presentation = student.code_presentation
  AND submission.id_student = student.id_student
WHERE submission.id_student IS NOT NULL
  AND submission.date_submitted IS NOT NULL
  AND submission.is_banked IN (0, 1)              -- binary flag: 0 = not banked, 1 = banked (carried over from previous attempt)
  AND (submission.score IS NULL OR submission.score BETWEEN 0 AND 100);  -- allow NULL scores (not graded yet) or valid percentages

-- clean student VLE interactions: aggregate click activity, link to valid students and VLE sites
CREATE OR REPLACE TABLE IDENTIFIER(clean_namespace || '.student_vle_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(interaction.code_module)) AS code_module,
  UPPER(TRIM(interaction.code_presentation)) AS code_presentation,
  interaction.id_student,
  interaction.id_site,
  interaction.date AS activity_date,
  SUM(interaction.sum_click) AS sum_click          -- aggregate clicks in case of duplicate records per student-site-date
FROM IDENTIFIER(raw_namespace || '.student_vle') AS interaction
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student  -- only interactions by valid students
  ON UPPER(TRIM(interaction.code_module)) = student.code_module
  AND UPPER(TRIM(interaction.code_presentation)) = student.code_presentation
  AND interaction.id_student = student.id_student
INNER JOIN IDENTIFIER(clean_namespace || '.vle_clean') AS activity         -- only interactions with valid VLE sites
  ON UPPER(TRIM(interaction.code_module)) = activity.code_module
  AND UPPER(TRIM(interaction.code_presentation)) = activity.code_presentation
  AND interaction.id_site = activity.id_site
WHERE interaction.date IS NOT NULL
  AND interaction.sum_click > 0                    -- only meaningful interactions (actual clicks)
GROUP BY
  UPPER(TRIM(interaction.code_module)),
  UPPER(TRIM(interaction.code_presentation)),
  interaction.id_student,
  interaction.id_site,
  interaction.date;
