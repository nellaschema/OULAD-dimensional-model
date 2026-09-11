-- Query: How does VLE engagement differ by final learner outcome?
-- Grain: One row per final-result category.

DECLARE OR REPLACE VARIABLE query_analytics_namespace STRING
  DEFAULT '`ftw-week-07`.`04-analytics`';

SELECT
  final_result,
  COUNT(*) AS student_course_count,
  AVG(active_days) AS average_active_days,
  AVG(total_clicks) AS average_total_clicks,
  PERCENTILE_APPROX(total_clicks, 0.5) AS median_total_clicks
FROM IDENTIFIER(query_analytics_namespace || '.student_engagement')
GROUP BY final_result
ORDER BY average_total_clicks DESC;
