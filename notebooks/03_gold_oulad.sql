-- Databricks notebook source
-- Build and validate the Gold layer after Silver succeeds.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/03_gold/sql/06_gold_dimensions

-- COMMAND ----------

-- MAGIC %run ../src/03_gold/sql/07_gold_facts

-- COMMAND ----------

-- MAGIC %run ../tests/08_validate_gold

-- COMMAND ----------

-- MAGIC %run ../src/03_gold/sql/08_gold_relationships