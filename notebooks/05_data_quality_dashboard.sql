-- Databricks notebook source
-- Refresh the core and governed dashboard views after all validators have completed.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/05_data_quality/sql/14_dq_dashboard_views
