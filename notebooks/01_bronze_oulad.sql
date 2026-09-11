-- Databricks notebook source
-- Build and validate the Bronze layer.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/01_bronze/sql/02_bronze_sources

-- COMMAND ----------

-- MAGIC %run ../tests/03_validate_bronze