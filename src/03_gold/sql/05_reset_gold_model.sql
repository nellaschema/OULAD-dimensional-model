-- Databricks notebook source
-- Name: 05 - Reset Gold Model
-- Purpose: Remove the previous three-fact/six-dimension model before the aligned rebuild.
-- Scope: Gold objects only; Bronze, Silver, Analytics, and DQ history are not changed.

DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

-- Drop facts first because they may contain informational foreign keys.
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_student_enrollment');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_assessment_submission');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_vle_interaction');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_assessments');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.fact_vle_interactions');

-- Drop role-playing views before their physical date dimension.
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_registration_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_unregistration_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_submission_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_due_date');
DROP VIEW IF EXISTS IDENTIFIER(mart_namespace || '.dim_activity_date');

-- Remove legacy process-specific dimensions and rebuild the five required dimensions.
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_assessment');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_vle_activity');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_relative_date');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_student');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_course');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_module_presentation');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_date');
DROP TABLE IF EXISTS IDENTIFIER(mart_namespace || '.dim_demographics');
