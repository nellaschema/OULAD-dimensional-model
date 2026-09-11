-- Metabase question 1: Outcome KPI cards
SELECT
  SUM(enrolled_students) AS total_enrollments,
  ROUND(
    100.0 * SUM(passed_students + distinction_students) / NULLIF(SUM(enrolled_students), 0),
    2
  ) AS successful_outcome_rate_pct,
  ROUND(
    100.0 * SUM(withdrawn_students) / NULLIF(SUM(enrolled_students), 0),
    2
  ) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.learner_outcomes
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]];

-- Metabase question 2: Assessment KPI cards
SELECT
  SUM(submission_count) AS submissions,
  ROUND(SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0), 2)
    AS average_assessment_score,
  ROUND(
    100.0 * SUM(passed_submission_count) / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS assessment_pass_rate_pct,
  ROUND(
    100.0 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{assessment_type}}]];

-- Metabase question 3: Enrollment outcomes by presentation
SELECT
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  final_result,
  COUNT(*) AS student_enrollments
FROM `ftw-week-07`.`04-analytics`.student_cohort
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{final_result}}]]
GROUP BY code_module, code_presentation, final_result
ORDER BY code_module, code_presentation, final_result;

-- Metabase question 4: Highest withdrawal-rate presentations
SELECT
  code_module,
  code_presentation,
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  enrolled_students,
  withdrawn_students,
  ROUND(100.0 * withdrawn_students / NULLIF(enrolled_students, 0), 2)
    AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.learner_outcomes
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
ORDER BY withdrawal_rate_pct DESC, enrolled_students DESC
LIMIT 10;

-- Metabase question 5: Engagement by final result
SELECT
  final_result,
  COUNT(*) AS student_enrollments,
  ROUND(AVG(active_days), 2) AS average_active_days,
  ROUND(AVG(total_clicks), 2) AS average_total_clicks
FROM `ftw-week-07`.`04-analytics`.student_engagement
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{final_result}}]]
GROUP BY final_result
ORDER BY average_total_clicks DESC;

-- Metabase question 6: Weekly VLE activity
SELECT
  presentation.code_module,
  presentation.code_presentation,
  CONCAT(presentation.code_module, ' - ', presentation.code_presentation)
    AS module_presentation,
  activity_date.relative_week,
  SUM(interaction.sum_click) AS total_clicks,
  COUNT(DISTINCT interaction.student_key) AS active_students
FROM `ftw-week-07`.`03-mart`.fact_vle_interactions AS interaction
INNER JOIN `ftw-week-07`.`03-mart`.dim_date AS activity_date
  ON interaction.activity_date_id = activity_date.date_key
INNER JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS presentation
  ON interaction.module_presentation_key = presentation.module_presentation_key
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
GROUP BY
  presentation.code_module,
  presentation.code_presentation,
  activity_date.relative_week
ORDER BY presentation.code_module, presentation.code_presentation, activity_date.relative_week;

-- Metabase question 7: Assessment performance by type
SELECT
  assessment_type,
  SUM(submission_count) AS submissions,
  ROUND(SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0), 2) AS average_score,
  ROUND(
    100.0 * SUM(passed_submission_count) / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS pass_rate_pct,
  ROUND(
    100.0 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{assessment_type}}]]
GROUP BY assessment_type
ORDER BY assessment_type;

-- Metabase question 8: Late-submission rate by module and assessment type
SELECT
  code_module,
  code_presentation,
  assessment_type,
  SUM(late_submission_count) AS late_submissions,
  SUM(dated_submission_count) AS due_dated_submissions,
  ROUND(
    100.0 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{assessment_type}}]]
GROUP BY code_module, code_presentation, assessment_type
ORDER BY late_submission_rate_pct DESC;

-- Metabase question 9: Withdrawal rate by age band
SELECT
  COALESCE(demographic.age_band, 'UNKNOWN') AS age_band,
  COUNT(*) AS student_enrollments,
  SUM(cohort.withdrawn_count) AS withdrawn_students,
  ROUND(100.0 * SUM(cohort.withdrawn_count) / NULLIF(COUNT(*), 0), 2)
    AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.student_cohort AS cohort
INNER JOIN `ftw-week-07`.`03-mart`.dim_demographics AS demographic
  ON cohort.demographics_key = demographic.demographics_key
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
GROUP BY COALESCE(demographic.age_band, 'UNKNOWN')
ORDER BY withdrawal_rate_pct DESC;

-- Metabase question 10: Rule-based risk distribution
SELECT
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  risk_level,
  COUNT(*) AS student_enrollments
FROM `ftw-week-07`.`04-analytics`.at_risk_students
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{risk_level}}]]
GROUP BY code_module, code_presentation, risk_level
ORDER BY code_module, code_presentation,
  CASE risk_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END;

-- Metabase question 11: Observed withdrawal rate by rule-based risk level
SELECT
  risk_level,
  COUNT(*) AS student_enrollments,
  COUNT_IF(final_result = 'Withdrawn') AS withdrawn_students,
  ROUND(
    100.0 * COUNT_IF(final_result = 'Withdrawn') / NULLIF(COUNT(*), 0),
    2
  ) AS observed_withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.at_risk_students
WHERE 1 = 1
  [[AND {{code_module}}]]
  [[AND {{code_presentation}}]]
  [[AND {{risk_level}}]]
GROUP BY risk_level
ORDER BY CASE risk_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END;
