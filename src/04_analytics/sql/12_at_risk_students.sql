-- Databricks notebook source
-- Name: 12 - At-Risk Students
-- Purpose: Create a transparent screening table from the two validated core facts.
-- Grain: One student in one module presentation.
-- Depends on: Gold assessment/VLE facts, dim_date, and Analytics student_cohort.
-- Produces: at_risk_students in 04-analytics.
-- Why: The assignment asks for dropout-risk analysis; a documented rule score
-- is interpretable and auditable without pretending to be a trained predictor.
-- Rerun behavior: The output is fully replaced.
-- Important: final_result is copied only for retrospective evaluation. It is
-- not used in risk_score, avoiding direct target leakage.
-- Documentation: See src/README.md and docs/decisions.md.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.at_risk_students')
USING DELTA
AS
-- Engagement signals summarize frequency and volume for each student and
-- presentation. Students with no fact rows are added later from student_cohort.
WITH engagement_signals AS (
  SELECT
    interaction.module_presentation_key,
    interaction.student_key,
    COUNT(DISTINCT relative_date.relative_day) AS active_days,
    SUM(interaction.sum_click) AS total_clicks
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interactions') AS interaction
  INNER JOIN IDENTIFIER(mart_namespace || '.dim_date') AS relative_date
    ON interaction.activity_date_id = relative_date.date_key
  GROUP BY interaction.module_presentation_key, interaction.student_key
),
-- Assessment signals summarize participation, observed performance, and late
-- work. A missing average remains null when no scored submission exists.
assessment_signals AS (
  SELECT
    fact.module_presentation_key,
    fact.student_key,
    COUNT(*) AS submission_count,
    AVG(fact.score) AS average_score,
    COUNT_IF(
      fact.due_date_key IS NOT NULL
      AND submission_date.relative_day > due_date.relative_day
    ) AS late_submission_count
  FROM IDENTIFIER(mart_namespace || '.fact_assessments') AS fact
  INNER JOIN IDENTIFIER(mart_namespace || '.dim_date') AS submission_date
    ON fact.submission_date_key = submission_date.date_key
  LEFT JOIN IDENTIFIER(mart_namespace || '.dim_date') AS due_date
    ON fact.due_date_key = due_date.date_key
  GROUP BY fact.module_presentation_key, fact.student_key
),
-- Join both signal sets to the full cohort and calculate a transparent score:
--   engagement: 2 points for zero clicks, 1 for fewer than 25;
--   assessment: 2 for no submissions or average below 40, 1 below 50;
--   registration: 1 for registering after the presentation began.
-- Thresholds are assignment heuristics for prioritization, not causal claims.
signals AS (
  SELECT
    cohort.student_cohort_key,
    cohort.module_presentation_key,
    cohort.course_key,
    cohort.student_key,
    cohort.demographics_key,
    cohort.code_module,
    cohort.code_presentation,
    cohort.id_student,
    cohort.date_registration,
    COALESCE(engagement.active_days, 0) AS active_days,
    COALESCE(engagement.total_clicks, 0) AS total_clicks,
    COALESCE(assessment.submission_count, 0) AS submission_count,
    assessment.average_score,
    COALESCE(assessment.late_submission_count, 0) AS late_submission_count,
    cohort.final_result,
    CASE
      WHEN COALESCE(engagement.total_clicks, 0) = 0 THEN 2
      WHEN engagement.total_clicks < 25 THEN 1
      ELSE 0
    END
      + CASE
        WHEN COALESCE(assessment.submission_count, 0) = 0 THEN 2
        WHEN assessment.average_score < 40 THEN 2
        WHEN assessment.average_score < 50 THEN 1
        ELSE 0
      END
      + CASE WHEN cohort.date_registration > 0 THEN 1 ELSE 0 END AS risk_score
  FROM IDENTIFIER(analytics_namespace || '.student_cohort') AS cohort
  LEFT JOIN engagement_signals AS engagement
    ON cohort.module_presentation_key = engagement.module_presentation_key
    AND cohort.student_key = engagement.student_key
  LEFT JOIN assessment_signals AS assessment
    ON cohort.module_presentation_key = assessment.module_presentation_key
    AND cohort.student_key = assessment.student_key
)
-- Translate the 0-5 score into simple operational bands. Keeping the numeric
-- score lets reviewers understand why a student entered a band.
SELECT
  student_cohort_key,
  module_presentation_key,
  course_key,
  student_key,
  demographics_key,
  code_module,
  code_presentation,
  id_student,
  date_registration,
  active_days,
  total_clicks,
  submission_count,
  average_score,
  late_submission_count,
  risk_score,
  CASE
    WHEN risk_score >= 4 THEN 'HIGH'
    WHEN risk_score >= 2 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS risk_level,
  final_result
FROM signals;
