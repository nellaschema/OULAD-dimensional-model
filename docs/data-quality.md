# OULAD Data Quality Documentation

## Purpose

This document describes the data-quality checks used in the OULAD dimensional model. The checks help ensure that data remains complete, valid, unique, and aligned across the Bronze, Silver, and Gold layers.

## Data Quality Layers

| Layer | Schema | Purpose |
|---|---|---|
| Bronze / Raw | `ftw-week-07`.`01-raw` | Validate ingested source data |
| Silver / Clean | `ftw-week-07`.`02-clean` | Validate standardized and conformed data |
| Gold / Mart | `ftw-week-07`.`03-mart` | Validate dimensions, facts, and relationships |

## Validation Files

| File | Layer | Purpose |
|---|---|---|
| `src/data-quality/raw-data-quality-check.sql` | Bronze / Raw | Checks required fields, valid values, duplicate keys, and basic consistency |
| `src/data-quality/cleaning-validation.sql` | Silver / Clean | Checks cleaned data, relationships, uniqueness, and completeness |
| `src/mart/cleaning_query.sql` | Gold / Mart | Checks duplicate business keys and fact-table relationships |

## Bronze / Raw Checks

The Raw layer checks include:

- Required fields are not null or blank
- Numeric values are valid
- Scores are within the expected range of 0 to 100
- Dates and week ranges are logically valid
- Business keys are unique
- Duplicate records are identified
- Invalid domain values are detected

The main validation file is:

```text
src/data-quality/raw-data-quality-check.sql

## Current Bronze/Raw Data Quality Findings

Two data-quality failures were detected in the Bronze/Raw layer:

1. `student_registration` — 45 records failed the required-key and valid-registration-date check.
2. `student_vle` — 2,195,960 duplicate records were detected at the daily student-activity grain.

These findings are documented for the respective Bronze/Silver owners to review. The Raw data is retained for traceability, while corrective handling should be applied in the Clean layer.