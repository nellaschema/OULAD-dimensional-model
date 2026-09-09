%sql


-- OULAD DATA QUALITY DASHBOARD

-- Purpose:
--   Validate raw OULAD tables across:
--   1. Completeness
--   2. Uniqueness
--   3. Validity
--   4. Referential Integrity
--
-- Status threshold:
--   Completeness checks with known/acceptable missingness are considered PASS when failure_rate <= 0.20%.
--
-- Notes:
--   - Negative relative dates in student_vle.date and student_assessment.date_submitted are valid in OULAD.
--   - Missing student_assessment.score and student_registration.
--     - date_registration are retained and evaluated against the 0.20% threshold.
--   - assessments.date may be NULL for Exam records.
--   - student_vle does not use (id_student, id_site, date) as a duplicate key because repeated interactions can legitimately occur at the same student/site/date.



-- COMPLETENESS


SELECT
    'assessments' AS table_name,
    'Completeness' AS dimension,
    'Missing id_assessment' AS check_name,
    COUNT_IF(id_assessment IS NULL) AS failed_rows,
    COUNT(*) AS total_rows,
    ROUND(COUNT_IF(id_assessment IS NULL) * 100.0 / COUNT(*), 2) AS failure_rate,
    CASE
        WHEN COUNT_IF(id_assessment IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Completeness',
    'Missing code_module',
    COUNT_IF(code_module IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Completeness',
    'Missing code_presentation',
    COUNT_IF(code_presentation IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Completeness',
    'Missing assessment_type',
    COUNT_IF(assessment_type IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(assessment_type IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(assessment_type IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Completeness',
    'Missing date for non-Exam assessment',
    COUNT_IF(date IS NULL AND assessment_type <> 'Exam'),
    COUNT(*),
    ROUND(
        COUNT_IF(date IS NULL AND assessment_type <> 'Exam') * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(date IS NULL AND assessment_type <> 'Exam') * 100.0 / COUNT(*) <= 0.20
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Completeness',
    'Missing weight',
    COUNT_IF(weight IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(weight IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(weight IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments


UNION ALL

SELECT
    'courses',
    'Completeness',
    'Missing code_module',
    COUNT_IF(code_module IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.courses

UNION ALL

SELECT
    'courses',
    'Completeness',
    'Missing code_presentation',
    COUNT_IF(code_presentation IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.courses

UNION ALL

SELECT
    'courses',
    'Completeness',
    'Missing module_presentation_length',
    COUNT_IF(module_presentation_length IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(module_presentation_length IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(module_presentation_length IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.courses


UNION ALL

SELECT
    'student_assessment',
    'Completeness',
    'Missing id_assessment',
    COUNT_IF(id_assessment IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_assessment IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_assessment IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment

UNION ALL

SELECT
    'student_assessment',
    'Completeness',
    'Missing id_student',
    COUNT_IF(id_student IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment

UNION ALL

SELECT
    'student_assessment',
    'Completeness',
    'Missing date_submitted',
    COUNT_IF(date_submitted IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(date_submitted IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(date_submitted IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment

UNION ALL

SELECT
    'student_assessment',
    'Completeness',
    'Missing score',
    COUNT_IF(score IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(score IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(score IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment


UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing id_student',
    COUNT_IF(id_student IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing code_module',
    COUNT_IF(code_module IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing code_presentation',
    COUNT_IF(code_presentation IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing gender',
    COUNT_IF(gender IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(gender IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(gender IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing age_band',
    COUNT_IF(age_band IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(age_band IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(age_band IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Completeness',
    'Missing final_result',
    COUNT_IF(final_result IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(final_result IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(final_result IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info


UNION ALL

SELECT
    'student_registration',
    'Completeness',
    'Missing id_student',
    COUNT_IF(id_student IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration

UNION ALL

SELECT
    'student_registration',
    'Completeness',
    'Missing code_module',
    COUNT_IF(code_module IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration

UNION ALL

SELECT
    'student_registration',
    'Completeness',
    'Missing code_presentation',
    COUNT_IF(code_presentation IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration

UNION ALL

SELECT
    'student_registration',
    'Completeness',
    'Missing date_registration',
    COUNT_IF(date_registration IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(date_registration IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(date_registration IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration


UNION ALL

SELECT
    'student_vle',
    'Completeness',
    'Missing id_student',
    COUNT_IF(id_student IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_student IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle

UNION ALL

SELECT
    'student_vle',
    'Completeness',
    'Missing id_site',
    COUNT_IF(id_site IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_site IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_site IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle

UNION ALL

SELECT
    'student_vle',
    'Completeness',
    'Missing date',
    COUNT_IF(date IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(date IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(date IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle

UNION ALL

SELECT
    'student_vle',
    'Completeness',
    'Missing sum_click',
    COUNT_IF(sum_click IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(sum_click IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(sum_click IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle


UNION ALL

SELECT
    'vle',
    'Completeness',
    'Missing id_site',
    COUNT_IF(id_site IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(id_site IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(id_site IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle

UNION ALL

SELECT
    'vle',
    'Completeness',
    'Missing code_module',
    COUNT_IF(code_module IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_module IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle

UNION ALL

SELECT
    'vle',
    'Completeness',
    'Missing code_presentation',
    COUNT_IF(code_presentation IS NULL),
    COUNT(*),
    ROUND(COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*), 2),
    CASE
        WHEN COUNT_IF(code_presentation IS NULL) * 100.0 / COUNT(*) <= 0.20 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle



-- UNIQUENESS


UNION ALL

SELECT
    'assessments',
    'Uniqueness',
    'Duplicate id_assessment',
    COUNT(*) - COUNT(DISTINCT id_assessment),
    COUNT(*),
    ROUND(
        (COUNT(*) - COUNT(DISTINCT id_assessment)) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(DISTINCT id_assessment) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'courses',
    'Uniqueness',
    'Duplicate course presentation',
    COUNT(*) - COUNT(DISTINCT CONCAT(code_module, '_', code_presentation)),
    COUNT(*),
    ROUND(
        (COUNT(*) - COUNT(DISTINCT CONCAT(code_module, '_', code_presentation))) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(DISTINCT CONCAT(code_module, '_', code_presentation)) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.courses

UNION ALL

SELECT
    'student_assessment',
    'Uniqueness',
    'Duplicate student assessment',
    COUNT(*) - COUNT(
        DISTINCT CONCAT(id_assessment, '_', id_student)
    ),
    COUNT(*),
    ROUND(
        (
            COUNT(*) - COUNT(
                DISTINCT CONCAT(id_assessment, '_', id_student)
            )
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(
            DISTINCT CONCAT(id_assessment, '_', id_student)
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment

UNION ALL

SELECT
    'student_info',
    'Uniqueness',
    'Duplicate student enrollment',
    COUNT(*) - COUNT(
        DISTINCT CONCAT(
            id_student,
            '_',
            code_module,
            '_',
            code_presentation
        )
    ),
    COUNT(*),
    ROUND(
        (
            COUNT(*) - COUNT(
                DISTINCT CONCAT(
                    id_student,
                    '_',
                    code_module,
                    '_',
                    code_presentation
                )
            )
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(
            DISTINCT CONCAT(
                id_student,
                '_',
                code_module,
                '_',
                code_presentation
            )
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_registration',
    'Uniqueness',
    'Duplicate student registration',
    COUNT(*) - COUNT(
        DISTINCT CONCAT(
            id_student,
            '_',
            code_module,
            '_',
            code_presentation
        )
    ),
    COUNT(*),
    ROUND(
        (
            COUNT(*) - COUNT(
                DISTINCT CONCAT(
                    id_student,
                    '_',
                    code_module,
                    '_',
                    code_presentation
                )
            )
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(
            DISTINCT CONCAT(
                id_student,
                '_',
                code_module,
                '_',
                code_presentation
            )
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration

UNION ALL

SELECT
    'vle',
    'Uniqueness',
    'Duplicate id_site',
    COUNT(*) - COUNT(DISTINCT id_site),
    COUNT(*),
    ROUND(
        (COUNT(*) - COUNT(DISTINCT id_site)) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT(*) - COUNT(DISTINCT id_site) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle



-- VALIDITY


UNION ALL

SELECT
    'assessments',
    'Validity',
    'Invalid weight',
    COUNT_IF(weight < 0 OR weight > 100),
    COUNT(*),
    ROUND(
        COUNT_IF(weight < 0 OR weight > 100) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(weight < 0 OR weight > 100) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Validity',
    'Invalid assessment type',
    COUNT_IF(
        assessment_type NOT IN ('TMA', 'CMA', 'Exam')
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            assessment_type NOT IN ('TMA', 'CMA', 'Exam')
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            assessment_type NOT IN ('TMA', 'CMA', 'Exam')
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments

UNION ALL

SELECT
    'assessments',
    'Validity',
    'Invalid date',
    COUNT_IF(date IS NOT NULL AND date < 0),
    COUNT(*),
    ROUND(
        COUNT_IF(date IS NOT NULL AND date < 0) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(date IS NOT NULL AND date < 0) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments


UNION ALL

SELECT
    'courses',
    'Validity',
    'Invalid module presentation length',
    COUNT_IF(module_presentation_length <= 0),
    COUNT(*),
    ROUND(
        COUNT_IF(module_presentation_length <= 0) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(module_presentation_length <= 0) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.courses


UNION ALL

SELECT
    'student_assessment',
    'Validity',
    'Invalid score',
    COUNT_IF(score IS NOT NULL AND (score < 0 OR score > 100)),
    COUNT(*),
    ROUND(
        COUNT_IF(
            score IS NOT NULL AND (score < 0 OR score > 100)
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            score IS NOT NULL AND (score < 0 OR score > 100)
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment

UNION ALL

SELECT
    'student_assessment',
    'Validity',
    'Date submitted outside valid range',
    COUNT_IF(
        date_submitted IS NOT NULL
        AND date_submitted > 650
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            date_submitted IS NOT NULL
            AND date_submitted > 650
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            date_submitted IS NOT NULL
            AND date_submitted > 650
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment


UNION ALL

SELECT
    'student_info',
    'Validity',
    'Invalid gender',
    COUNT_IF(gender NOT IN ('M', 'F')),
    COUNT(*),
    ROUND(
        COUNT_IF(gender NOT IN ('M', 'F')) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(gender NOT IN ('M', 'F')) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Validity',
    'Invalid age_band',
    COUNT_IF(
        age_band NOT IN ('0-35', '35-55', '55<=')
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            age_band NOT IN ('0-35', '35-55', '55<=')
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            age_band NOT IN ('0-35', '35-55', '55<=')
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info

UNION ALL

SELECT
    'student_info',
    'Validity',
    'Invalid studied_credits',
    COUNT_IF(
        studied_credits IS NOT NULL
        AND studied_credits < 0
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            studied_credits IS NOT NULL
            AND studied_credits < 0
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            studied_credits IS NOT NULL
            AND studied_credits < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info


UNION ALL

SELECT
    'student_registration',
    'Validity',
    'Invalid date_registration',
    COUNT_IF(
        date_registration IS NOT NULL
        AND date_registration > 650
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            date_registration IS NOT NULL
            AND date_registration > 650
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            date_registration IS NOT NULL
            AND date_registration > 650
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration


UNION ALL

SELECT
    'student_vle',
    'Validity',
    'Invalid sum_click',
    COUNT_IF(
        sum_click IS NOT NULL
        AND sum_click < 0
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            sum_click IS NOT NULL
            AND sum_click < 0
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            sum_click IS NOT NULL
            AND sum_click < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle


UNION ALL

SELECT
    'vle',
    'Validity',
    'Invalid week_from',
    COUNT_IF(
        week_from IS NOT NULL
        AND week_from < 0
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            week_from IS NOT NULL
            AND week_from < 0
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            week_from IS NOT NULL
            AND week_from < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle

UNION ALL

SELECT
    'vle',
    'Validity',
    'Invalid week_to',
    COUNT_IF(
        week_to IS NOT NULL
        AND week_to < 0
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            week_to IS NOT NULL
            AND week_to < 0
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            week_to IS NOT NULL
            AND week_to < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle

UNION ALL

SELECT
    'vle',
    'Validity',
    'Invalid activity_type',
    COUNT_IF(
        activity_type NOT IN (
            'resource',
            'oucontent',
            'url',
            'homepage',
            'subpage',
            'glossary',
            'forumng',
            'oucollaborate',
            'dataplus',
            'quiz',
            'ouelluminate',
            'sharedsubpage',
            'questionnaire',
            'page',
            'externalquiz',
            'ouwiki',
            'dualpane',
            'repeatactivity',
            'folder',
            'htmlactivity'
        )
    ),
    COUNT(*),
    ROUND(
        COUNT_IF(
            activity_type NOT IN (
                'resource',
                'oucontent',
                'url',
                'homepage',
                'subpage',
                'glossary',
                'forumng',
                'oucollaborate',
                'dataplus',
                'quiz',
                'ouelluminate',
                'sharedsubpage',
                'questionnaire',
                'page',
                'externalquiz',
                'ouwiki',
                'dualpane',
                'repeatactivity',
                'folder',
                'htmlactivity'
            )
        ) * 100.0 / COUNT(*),
        2
    ),
    CASE
        WHEN COUNT_IF(
            activity_type NOT IN (
                'resource',
                'oucontent',
                'url',
                'homepage',
                'subpage',
                'glossary',
                'forumng',
                'oucollaborate',
                'dataplus',
                'quiz',
                'ouelluminate',
                'sharedsubpage',
                'questionnaire',
                'page',
                'externalquiz',
                'ouwiki',
                'dualpane',
                'repeatactivity',
                'folder',
                'htmlactivity'
            )
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle



-- REFERENTIAL INTEGRITY


UNION ALL

SELECT
    'assessments',
    'Referential Integrity',
    'Assessment course not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.assessments),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.assessments),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.assessments a
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.courses c
    WHERE c.code_module = a.code_module
      AND c.code_presentation = a.code_presentation
)


UNION ALL

SELECT
    'student_assessment',
    'Referential Integrity',
    'Assessment reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_assessment),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_assessment),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment sa
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.assessments a
    WHERE a.id_assessment = sa.id_assessment
)


UNION ALL

SELECT
    'student_assessment',
    'Referential Integrity',
    'Student reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_assessment),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_assessment),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_assessment sa
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.student_info si
    WHERE si.id_student = sa.id_student
)


UNION ALL

SELECT
    'student_info',
    'Referential Integrity',
    'Course reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_info),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_info),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_info si
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.courses c
    WHERE c.code_module = si.code_module
      AND c.code_presentation = si.code_presentation
)


UNION ALL

SELECT
    'student_registration',
    'Referential Integrity',
    'Student enrollment reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_registration),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_registration),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration sr
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.student_info si
    WHERE si.id_student = sr.id_student
      AND si.code_module = sr.code_module
      AND si.code_presentation = sr.code_presentation
)


UNION ALL

SELECT
    'student_registration',
    'Referential Integrity',
    'Course reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_registration),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_registration),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_registration sr
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.courses c
    WHERE c.code_module = sr.code_module
      AND c.code_presentation = sr.code_presentation
)


UNION ALL

SELECT
    'student_vle',
    'Referential Integrity',
    'Student reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_vle),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_vle),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle sv
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.student_info si
    WHERE si.id_student = sv.id_student
)


UNION ALL

SELECT
    'student_vle',
    'Referential Integrity',
    'VLE site reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_vle),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.student_vle),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.student_vle sv
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.vle v
    WHERE v.id_site = sv.id_site
)


UNION ALL

SELECT
    'vle',
    'Referential Integrity',
    'Course reference not found',
    COUNT(*),
    (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.vle),
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `ftw-week-07`.`01-raw`.vle),
        2
    ),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM `ftw-week-07`.`01-raw`.vle v
WHERE NOT EXISTS (
    SELECT 1
    FROM `ftw-week-07`.`01-raw`.courses c
    WHERE c.code_module = v.code_module
      AND c.code_presentation = v.code_presentation
)

ORDER BY
    table_name,
    dimension,
    check_name;
