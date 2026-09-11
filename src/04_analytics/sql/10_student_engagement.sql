-- Databricks notebook source
-- Name: 10 - Student Engagement
-- Purpose: Relate daily VLE engagement to each student's final performance outcome.
-- Grain: One student and module presentation, including students with no VLE activity.
-- Depends on: Gold fact_vle_interactions/dim_date and Analytics student_cohort.
-- Produces: student_engagement in 04-analytics.
-- Why: The table answers whether engagement relates to performance while using
-- the full enrollment cohort instead of only students who generated VLE events.
-- Rerun behavior: The output is fully replaced.
-- Interpretation: Counts describe observed platform activity, not learning time
-- or causation; dashboards should present the relationship as an association.
-- Documentation: See src/README.md and dashboard/oulad-analytics-dashboard.md.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.student_engagement')
USING DELTA
AS
-- First compress the daily fact to one engagement summary per student and
-- presentation. Distinct relative days measure frequency; total clicks measure
-- volume; first/last day describe the observed activity span.
WITH engagement AS (
  SELECT
    interaction.module_presentation_key,
    interaction.student_key,
    COUNT(DISTINCT relative_date.relative_day) AS active_days,
    COUNT(DISTINCT interaction.id_site) AS activities_used,
    SUM(interaction.sum_click) AS total_clicks,
    MIN(relative_date.relative_day) AS first_activity_day,
    MAX(relative_date.relative_day) AS last_activity_day
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interactions') AS interaction
  INNER JOIN IDENTIFIER(mart_namespace || '.dim_date') AS relative_date
    ON interaction.activity_date_id = relative_date.date_key
  GROUP BY interaction.module_presentation_key, interaction.student_key
)
-- student_cohort is deliberately on the left. COALESCE converts missing event
-- aggregates to zero while leaving first/last activity day null, which clearly
-- distinguishes no activity from activity on relative day zero.
SELECT
  cohort.student_cohort_key,
  cohort.module_presentation_key,
  cohort.course_key,
  cohort.student_key,
  cohort.demographics_key,
  cohort.code_module,
  cohort.code_presentation,
  cohort.id_student,
  COALESCE(engagement.active_days, 0) AS active_days,
  COALESCE(engagement.activities_used, 0) AS activities_used,
  COALESCE(engagement.total_clicks, 0) AS total_clicks,
  engagement.first_activity_day,
  engagement.last_activity_day,
  CASE
    WHEN COALESCE(engagement.active_days, 0) = 0 THEN 0.0
    ELSE engagement.total_clicks * 1.0 / engagement.active_days
  END AS average_clicks_per_active_day,
  cohort.final_result
FROM IDENTIFIER(analytics_namespace || '.student_cohort') AS cohort
LEFT JOIN engagement
  ON cohort.module_presentation_key = engagement.module_presentation_key
  AND cohort.student_key = engagement.student_key;
