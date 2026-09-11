# Data dictionary

## Core dimensions

| Dimension | Key | Main attributes |
|---|---|---|
| `dim_student` | `student_key` | `id_student` |
| `dim_course` | `course_key` | `code_module` |
| `dim_module_presentation` | `module_presentation_key` | `course_key`, module code, presentation code, length |
| `dim_date` | `date_key` | relative day, relative week, course phase |
| `dim_demographics` | `demographics_key` | gender, region, education, IMD band, age band, disability |

## Core facts

| Fact | Grain | Main measures and descriptors |
|---|---|---|
| `fact_assessments` | Student assessment submission | assessment ID/type, decimal weight, banked flag, score |
| `fact_vle_interactions` | Student, module presentation, VLE site, relative day | site ID/type and aggregated clicks |

All fact foreign keys use the `<dimension>_key` convention except
`activity_date_id`, whose name follows the approved final diagram. The two
assessment date roles and the VLE activity date all reference
`dim_date.date_key`.

## Supporting Analytics models

| Model | Grain | Purpose |
|---|---|---|
| `student_cohort` | Student and module presentation | Complete cohort/dropout denominator, final result, and withdrawal flag |
| `learner_outcomes` | Module presentation | Enrollment and outcome totals |
| `student_engagement` | Student and module presentation | Engagement related to final performance |
| `assessment_performance` | Module presentation and assessment type | Additive assessment controls and rates |
| `at_risk_students` | Student and module presentation | Transparent rule-based screening |

## Assessment controls

| Column | Meaning |
|---|---|
| `submission_count` | All submissions |
| `scored_submission_count` | Non-null scores |
| `missing_score_count` | Null scores |
| `score_sum` | Sum of non-null scores |
| `passed_submission_count` | Scored submissions with score at least 40 |
| `dated_submission_count` | Submissions with a known due offset |
| `late_submission_count` | Due-dated submissions after the due offset |

Recalculate rates from these additive controls; do not average stored rates.
