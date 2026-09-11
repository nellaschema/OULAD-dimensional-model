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

### Current Data Quality Findings

- 45 invalid student registration rows were identified because of missing required values or inconsistent registration dates. These rows are excluded from the Clean layer.
- 2,195,960 duplicate student VLE rows were identified at the expected daily activity grain. The Raw layer is retained for traceability, while the Clean layer keeps one record per valid business key using ROW_NUMBER().
- The issue may have resulted from repeated ingestion or duplicated source records and will be monitored in future pipeline runs.