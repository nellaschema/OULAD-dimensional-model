-- Query: Which course presentations have the largest high-risk learner share?
-- Grain: One row per course presentation.

DECLARE OR REPLACE VARIABLE query_analytics_namespace STRING
  DEFAULT '`ftw-week-07`.`04-analytics`';

SELECT
  code_module,
  code_presentation,
  COUNT(*) AS enrolled_students,
  COUNT_IF(risk_level = 'HIGH') AS high_risk_students,
  AVG(CASE WHEN risk_level = 'HIGH' THEN 1.0 ELSE 0.0 END) AS high_risk_share
FROM IDENTIFIER(query_analytics_namespace || '.at_risk_students')
GROUP BY
  code_module,
  code_presentation
ORDER BY high_risk_share DESC;
