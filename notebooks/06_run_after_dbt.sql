-- Databricks notebook source
-- Run after `dbt build --select path:models/mart` completes successfully.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../tests/08_validate_gold

-- COMMAND ----------

-- MAGIC %run ../src/03_gold/sql/08_gold_relationships

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

-- COMMAND ----------

-- MAGIC %run ../src/05_data_quality/sql/14_dq_dashboard_views
