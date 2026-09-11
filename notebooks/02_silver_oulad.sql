-- Databricks notebook source
-- Build and validate the Silver layer after Bronze succeeds.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/02_silver/sql/04_silver_tables

-- COMMAND ----------

-- MAGIC %run ../tests/05_validate_silver
