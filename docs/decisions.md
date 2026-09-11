# Engineering decisions

## Exact assignment model

The core Gold mart has two facts (`fact_assessments` and
`fact_vle_interactions`) and five dimensions (Student, Course, Module
Presentation, Date, Demographics). Assessment and VLE attributes are stored in
their respective facts because the assignment does not list separate
Assessment or VLE dimensions.

## Course and presentation remain separate

Course is one module code. Module Presentation is one run of that module and
owns presentation code and length. Both facts hold both keys for direct BI
filtering; dbt verifies the course/presentation mapping.

## Enrollment is supporting Analytics data

A complete cohort is required for dropout denominators, but Enrollment is not a
required core fact. `student_cohort` therefore lives in Analytics as a
supporting reporting table rather than a third Gold fact. It contains
`final_result` and derived `is_withdrawn` because both describe a student's
enrollment in one module presentation.

## Relative dates

OULAD dates are offsets from presentation start. One physical `dim_date` is
reused for submission, due, and activity roles; no calendar date is invented.

## Student and demographics stay separate

Some students have different source profiles across module presentations.
`dim_demographics` contains demographic attributes only, and its deterministic
hash uses only those attributes. Outcomes are not demographics: `final_result`
and `is_withdrawn` remain in Analytics `student_cohort` at the student + module
+ presentation enrollment grain. The demographic surrogate key is not labeled
SCD Type 2 because there are no reliable effective dates or current-row
indicator.

## Full refresh and quality gates

The supplied data is a fixed snapshot. Full refresh is deterministic and easier
to reconcile. Every layer writes DQ results before a critical gate. Accuracy is
consolidated in Analytics validation as control-total reconciliation.

## Honest metrics

The 173 source-null scores remain null. Assessment rates use scored submissions
as the denominator, late rates use due-dated submissions, and risk is described
as rule-based screening rather than prediction.
