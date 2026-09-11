-- Databricks notebook source
-- Build Analytics and validate reporting grains plus cross-layer Accuracy controls.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/09_learner_outcomes

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/10_student_engagement

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/11_assessment_performance

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/12_at_risk_students

-- COMMAND ----------

-- MAGIC %run ../tests/13_validate_analytics