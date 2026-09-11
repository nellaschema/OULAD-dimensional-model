-- Databricks notebook source
-- Name: 08 - Gold Relationships
-- Purpose: Register the two-fact/five-dimension model in Catalog Explorer.
-- Prerequisite: Gold validation must pass before this file is called.
-- Depends on: tests/08_validate_gold.sql proving non-null, unique, and matching keys.
-- Produces: Seven primary-key and eleven foreign-key metadata constraints.
-- Why: Catalog Explorer and BI tools can discover the star relationships, but
-- Databricks PK/FK constraints are informational and do not clean bad rows.
-- Rerun behavior: Existing named constraints are dropped, then recreated.
-- Required access: Run as an owner of the participating Unity Catalog tables.
-- Documentation: See src/README.md and docs/data-model.md.

-- Remove foreign keys before primary keys because a referenced parent key cannot
-- be dropped safely while child constraints still depend on it.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_student;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_course;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_submission_date;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS fk_assessments_due_date;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS fk_vle_interactions_student;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS fk_vle_interactions_course;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS fk_vle_interactions_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS fk_vle_interactions_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS fk_vle_interactions_activity_date;

-- Remove prior primary-key declarations so this file can be rerun after a full
-- table replacement without accumulating conflicting metadata.
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  DROP CONSTRAINT IF EXISTS pk_dim_student;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_course
  DROP CONSTRAINT IF EXISTS pk_dim_course;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  DROP CONSTRAINT IF EXISTS pk_dim_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_date
  DROP CONSTRAINT IF EXISTS pk_dim_date;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  DROP CONSTRAINT IF EXISTS pk_dim_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  DROP CONSTRAINT IF EXISTS pk_fact_assessments;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  DROP CONSTRAINT IF EXISTS pk_fact_vle_interactions;

-- Primary-key columns must be NOT NULL before their informational PK constraint
-- can be registered. Gold validation has already checked these values.
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  ALTER COLUMN student_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_course
  ALTER COLUMN course_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  ALTER COLUMN module_presentation_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_date
  ALTER COLUMN date_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  ALTER COLUMN demographics_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ALTER COLUMN assessment_submission_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ALTER COLUMN vle_interaction_key SET NOT NULL;

-- Declare one key for each of the five dimensions and two facts.
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  ADD CONSTRAINT pk_dim_student PRIMARY KEY (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_course
  ADD CONSTRAINT pk_dim_course PRIMARY KEY (course_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  ADD CONSTRAINT pk_dim_module_presentation PRIMARY KEY (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_date
  ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  ADD CONSTRAINT pk_dim_demographics PRIMARY KEY (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT pk_fact_assessments PRIMARY KEY (assessment_submission_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT pk_fact_vle_interactions PRIMARY KEY (vle_interaction_key);

-- Assessment fact: every dimension connects directly to the fact.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_student
  FOREIGN KEY (student_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_student (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_course
  FOREIGN KEY (course_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_course (course_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_module_presentation
  FOREIGN KEY (module_presentation_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_module_presentation (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_demographics
  FOREIGN KEY (demographics_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_demographics (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_submission_date
  FOREIGN KEY (submission_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_date (date_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessments
  ADD CONSTRAINT fk_assessments_due_date
  FOREIGN KEY (due_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_date (date_key);

-- VLE fact: every dimension connects directly to the fact.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT fk_vle_interactions_student
  FOREIGN KEY (student_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_student (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT fk_vle_interactions_course
  FOREIGN KEY (course_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_course (course_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT fk_vle_interactions_module_presentation
  FOREIGN KEY (module_presentation_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_module_presentation (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT fk_vle_interactions_demographics
  FOREIGN KEY (demographics_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_demographics (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interactions
  ADD CONSTRAINT fk_vle_interactions_activity_date
  FOREIGN KEY (activity_date_id)
  REFERENCES `ftw-week-07`.`03-mart`.dim_date (date_key);

-- Expect 18 constraints: seven PKs and eleven FKs.
SELECT
  table_name,
  constraint_name,
  constraint_type
FROM `ftw-week-07`.information_schema.table_constraints
WHERE table_schema = '03-mart'
  AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY table_name, constraint_type, constraint_name;
