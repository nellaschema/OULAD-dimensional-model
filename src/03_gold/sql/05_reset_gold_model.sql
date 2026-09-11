-- Databricks notebook source
-- Name: 05 - Reset Gold Model
-- Purpose: Remove the previous three-fact/six-dimension model before the aligned rebuild.
-- Scope: Gold objects only; Bronze, Silver, Analytics, and DQ history are not changed.
-- Depends on: A deliberate decision to perform the assignment's full Gold rebuild.
-- Produces: An empty 03-mart target ready for the five-dimension/two-fact model.
-- Why: Legacy object names and extra facts/dimensions conflict with the final
-- dimensional contract and can leave misleading tables in Catalog Explorer.
-- Rerun behavior: DROP ... IF EXISTS makes the reset repeatable, but it is
-- intentionally destructive inside 03-mart. Do not run it to preserve Gold data.
-- Documentation: See src/README.md and docs/decisions.md.

DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

-- Drop facts first because they may contain informational foreign keys pointing
-- to dimensions. Removing children before parents avoids dependency failures.
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_student_enrollment');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_assessment_submission');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_vle_interaction');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_assessments');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_vle_interactions');

-- Drop role-playing views before their physical date dimension. These views are
-- labels for date roles, not additional physical dimensions.
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_registration_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_unregistration_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_submission_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_due_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_activity_date');

-- Remove legacy process-specific dimensions and rebuild the five required
-- dimensions so the catalog matches the submitted star-schema diagram exactly.
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_assessment');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_vle_activity');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_relative_date');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_student');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_course');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_module_presentation');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_date');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_demographics');
