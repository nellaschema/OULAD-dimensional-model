-- Databricks notebook source
-- Name: 11 - Assessment Performance
-- Purpose: Publish additive assessment controls and descriptive metrics.
-- Grain: One module presentation and assessment type.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.assessment_performance')
USING DELTA
AS
SELECT
  fact.module_presentation_key,
  fact.course_key,
  presentation.code_module,
  presentation.code_presentation,
  fact.assessment_type,
  COUNT(*) AS submission_count,
  COUNT(DISTINCT fact.student_key) AS submitting_students,
  COUNT_IF(fact.score IS NOT NULL) AS scored_submission_count,
  COUNT_IF(fact.score IS NULL) AS missing_score_count,
  SUM(COALESCE(fact.score, 0)) AS score_sum,
  COUNT_IF(fact.score IS NOT NULL AND fact.score >= 40) AS passed_submission_count,
  COUNT_IF(fact.due_date_key IS NOT NULL) AS dated_submission_count,
  COUNT_IF(
    fact.due_date_key IS NOT NULL
    AND submission_date.relative_day > due_date.relative_day
  ) AS late_submission_count,
  AVG(fact.score) AS average_score,
  PERCENTILE_APPROX(fact.score, 0.5) AS median_score,
  1.0 * COUNT_IF(fact.score IS NOT NULL AND fact.score >= 40)
    / NULLIF(COUNT_IF(fact.score IS NOT NULL), 0) AS pass_rate,
  1.0 * COUNT_IF(
    fact.due_date_key IS NOT NULL
    AND submission_date.relative_day > due_date.relative_day
  ) / NULLIF(COUNT_IF(fact.due_date_key IS NOT NULL), 0) AS late_submission_rate
FROM IDENTIFIER(mart_namespace || '.fact_assessments') AS fact
INNER JOIN IDENTIFIER(mart_namespace || '.dim_module_presentation') AS presentation
  ON fact.module_presentation_key = presentation.module_presentation_key
INNER JOIN IDENTIFIER(mart_namespace || '.dim_date') AS submission_date
  ON fact.submission_date_key = submission_date.date_key
LEFT JOIN IDENTIFIER(mart_namespace || '.dim_date') AS due_date
  ON fact.due_date_key = due_date.date_key
GROUP BY
  fact.module_presentation_key,
  fact.course_key,
  presentation.code_module,
  presentation.code_presentation,
  fact.assessment_type;
