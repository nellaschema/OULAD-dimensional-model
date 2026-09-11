-- Databricks notebook source
-- Run the complete full-refresh pipeline in dependency order.

-- COMMAND ----------
-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------
-- MAGIC %run ../src/01_bronze/sql/02_bronze_sources

-- COMMAND ----------
-- MAGIC %run ../tests/03_validate_bronze

-- COMMAND ----------
-- MAGIC %run ../src/02_silver/sql/04_silver_tables

-- COMMAND ----------
-- MAGIC %run ../tests/05_validate_silver

-- COMMAND ----------
-- MAGIC %run ../src/03_gold/sql/05_reset_gold_model

-- COMMAND ----------
-- MAGIC %run ../src/03_gold/sql/06_gold_dimensions

-- COMMAND ----------
-- MAGIC %run ../src/03_gold/sql/07_gold_facts

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
