# OULAD Raw Data Quality Checks

## Overview

This document describes the Data Quality (DQ) validation performed on the raw OULAD (Open University Learning Analytics Dataset) tables in the `01-raw` layer.

The validation evaluates whether the raw dataset meets defined criteria for completeness, uniqueness, validity, and referential integrity before progression to the clean/silver layer of the Medallion Architecture.

The DQ checks were implemented in Databricks SQL across four dimensions:

1. **Completeness**
2. **Uniqueness**
3. **Validity**
4. **Referential Integrity**

---

## Dataset Scope

The following raw OULAD tables were validated:

| Table                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| `assessments`          | Assessment definitions, types, dates, and weights |
| `courses`              | Module and presentation information               |
| `student_assessment`   | Student assessment submissions and scores         |
| `student_info`         | Student demographic and academic information      |
| `student_registration` | Student registration records                      |
| `student_vle`          | Student interaction with VLE activities           |
| `vle`                  | Virtual Learning Environment activity definitions |

The validation covers more than **10.8 million rows** across the raw dataset, including student interaction telemetry and relational structures.

---

# Data Quality Dimensions

## 1. Completeness

Completeness checks identify missing values in important columns.

A **0.20% tolerance threshold** is applied to completeness checks where a small amount of missing data is considered acceptable. The validation reports both the number of missing records and the resulting failure rate.

The status is determined using:

```sql
CASE
    WHEN failure_rate <= 0.20 THEN 'PASS'
    ELSE 'FAIL'
END
```

The DQ report distinguishes between:

* no missing values;
* missing values within the accepted tolerance; and
* missing values exceeding the defined tolerance.

### OULAD-Specific Completeness Rules

Some missing values require dataset-specific treatment.

### `assessments.date`

Some assessment dates are `NULL`. These values are expected for final examinations because examination dates are not represented in the same way as other assessment activities.

The validation therefore flags missing dates only for non-examination assessments:

```sql
date IS NULL
AND assessment_type <> 'Exam'
```

### `student_assessment.score`

Some assessment scores are missing.

`NULL` scores are retained in the raw layer rather than converted to zero. The completeness check evaluates the missing values against the **0.20% tolerance threshold**.

### `student_registration.date_registration`

Some registration dates are missing.

The values remain unchanged in the raw layer and are evaluated against the **0.20% tolerance threshold**.

---

## 2. Uniqueness

Uniqueness checks identify duplicate records using defined business keys.

The following keys are validated:

| Table                  | Business Key                                     |
| ---------------------- | ------------------------------------------------ |
| `assessments`          | `id_assessment`                                  |
| `courses`              | `code_module`, `code_presentation`               |
| `student_assessment`   | `id_assessment`, `id_student`                    |
| `student_info`         | `id_student`, `code_module`, `code_presentation` |
| `student_registration` | `id_student`, `code_module`, `code_presentation` |
| `vle`                  | `id_site`                                        |

### `student_vle` Duplicate Handling

A uniqueness check is not applied to:

```text
(id_student, id_site, date)
```

Multiple records with the same student, VLE site, and relative day can represent legitimate repeated interactions.

Using this combination as a strict uniqueness key could therefore classify valid telemetry records as duplicates.

---

## 3. Validity

Validity checks verify that values conform to expected domains, ranges, and business rules.

### `assessments`

The following rules are applied:

* `weight` must be between 0 and 100.
* `assessment_type` must be one of:

  * `TMA`
  * `CMA`
  * `Exam`
* Populated assessment dates must not be negative.

### `courses`

`module_presentation_length` must be greater than zero.

### `student_assessment`

The following rules are applied:

* Populated `score` values must be between 0 and 100.
* Negative `date_submitted` values are valid because OULAD uses relative dates.

Negative values are not classified as invalid.

### `student_info`

The following rules are applied.

`gender` must contain:

```text
M
F
```

`age_band` must contain one of:

```text
0-35
35-55
55<=
```

The values must match these literals exactly.

`studied_credits` must not be negative.

### `student_registration`

Populated registration dates must not exceed the defined upper boundary of 650 days.

### `student_vle`

`sum_click` must not be negative.

The `date` column is not subjected to a non-negative constraint because negative relative days are valid in the OULAD dataset.

### `vle`

`week_from` and `week_to` must not be negative.

`activity_type` must belong to the OULAD activity-type domain:

```text
resource
oucontent
url
homepage
subpage
glossary
forumng
oucollaborate
dataplus
quiz
ouelluminate
sharedsubpage
questionnaire
page
externalquiz
ouwiki
dualpane
repeatactivity
folder
htmlactivity
```

---

# 4. Referential Integrity

Referential integrity checks verify that records reference corresponding records in related tables.

The following relationships are validated:

| Child Table            | Parent Table   | Relationship                                     |
| ---------------------- | -------------- | ------------------------------------------------ |
| `assessments`          | `courses`      | `code_module`, `code_presentation`               |
| `student_assessment`   | `assessments`  | `id_assessment`                                  |
| `student_assessment`   | `student_info` | `id_student`                                     |
| `student_info`         | `courses`      | `code_module`, `code_presentation`               |
| `student_registration` | `student_info` | `id_student`, `code_module`, `code_presentation` |
| `student_registration` | `courses`      | `code_module`, `code_presentation`               |
| `student_vle`          | `student_info` | `id_student`                                     |
| `student_vle`          | `vle`          | `id_site`                                        |
| `vle`                  | `courses`      | `code_module`, `code_presentation`               |

The checks identify orphan records where a referenced parent record does not exist.

Example:

```sql
WHERE NOT EXISTS (
    SELECT 1
    FROM parent_table p
    WHERE p.key = child.key
)
```

A referential-integrity check passes when the resulting orphan count is zero.

---

# DQ Validation Query

The complete DQ validation is implemented in the Databricks notebook:

```text
07_01_oulad_raw_data_quality
```

The query produces a standardized DQ result containing:

| Column         | Description                             |
| -------------- | --------------------------------------- |
| `table_name`   | Raw table being evaluated               |
| `dimension`    | DQ dimension                            |
| `check_name`   | Specific validation rule                |
| `failed_rows`  | Number of records failing the check     |
| `total_rows`   | Total records evaluated                 |
| `failure_rate` | Percentage of records failing the check |
| `status`       | `PASS` or `FAIL`                        |

The output follows this structure:

```text
table_name
dimension
check_name
failed_rows
total_rows
failure_rate
status
```

---

# Final DQ Results

The final DQ validation produced the following health summary:

| Metric                          |             Result |
| ------------------------------- | -----------------: |
| Total Checks Run                |                 59 |
| Total Checks Passed             |                 59 |
| Total Checks Failed             |                  0 |
| Overall DQ Pass Rate            |               100% |
| Dataset Coverage                | 10.8+ million rows |
| Referential Integrity Pass Rate |               100% |
| Orphan References               |                  0 |
| Overall Status                  |           **PASS** |

---

# DQ Health Summary

## Completeness

All completeness checks passed under the defined rules and tolerance threshold.

Limited missing values were identified in selected fields, including:

* `student_assessment.score`
* `student_registration.date_registration`

These values remained unchanged in the raw layer and were evaluated against the **0.20% tolerance threshold**.

Missing assessment dates for examination records were handled according to the OULAD data structure.

## Uniqueness

All defined uniqueness checks passed.

No duplicate records were detected for the specified business keys.

The `student_vle` table was not evaluated using `(id_student, id_site, date)` as a uniqueness key because repeated VLE interactions can represent valid records.

## Validity

All implemented validity checks passed.

The validation incorporates OULAD-specific characteristics, including:

* negative relative dates;
* expected missing examination dates;
* exact `age_band` values;
* the defined VLE activity-type domain;
* valid assessment score ranges; and
* the defined upper boundary for assessment submission dates.

## Referential Integrity

All referential integrity checks passed.

A total of **0 orphan references** were detected across the validated table relationships.

The results confirm structural consistency across the validated assessment, student, course, registration, and VLE relationships.

---

# Data Quality Status

## PASS

The raw OULAD dataset achieved:

**59 / 59 DQ checks passed**

**100% overall DQ pass rate**

**0 referential integrity failures**

**0 orphan references**

Based on the defined DQ criteria, the raw dataset meets the established raw-layer validation requirements and is suitable for progression to the clean/silver layer.

---

# DQ Rules Summary

| Dimension             | Key Validation        | Threshold / Rule     |
| --------------------- | --------------------- | -------------------- |
| Completeness          | Required fields       | ≤ 0.20% missing      |
| Uniqueness            | Defined business keys | 0 duplicates         |
| Validity              | Assessment weight     | 0–100                |
| Validity              | Assessment score      | 0–100                |
| Validity              | Assessment type       | TMA, CMA, Exam       |
| Validity              | `age_band`            | 0-35, 35-55, 55<=    |
| Validity              | `sum_click`           | ≥ 0                  |
| Validity              | VLE weeks             | ≥ 0                  |
| Validity              | VLE activity type     | Defined OULAD domain |
| Validity              | `date_submitted`      | ≤ 650                |
| Referential Integrity | Table relationships   | 0 orphan records     |

---

# Raw Layer DQ Design Principles

The following principles guide the raw-layer validation.

### Preserve Raw Data

The DQ process identifies data quality issues without modifying source records in the raw layer.

Cleaning, standardization, imputation, and business-rule transformations are handled in the subsequent clean/silver layer.

### Use Dataset-Aware Rules

Validation rules reflect the characteristics of the OULAD dataset rather than generic assumptions.

For example, negative relative dates are valid OULAD values and are not automatically classified as errors.

### Distinguish Missingness from Invalidity

A missing value is evaluated separately from an invalid value.

Missing values are assessed using the defined completeness threshold, while invalid values are evaluated against domain and range rules.

### Validate Relationships

Data quality extends beyond individual columns. Referential integrity checks evaluate whether records maintain valid relationships across the relational structure of the dataset.

### Report Actual Failures

The DQ output reports the number of affected rows and the calculated failure rate, including checks that pass because the failure rate remains within the accepted tolerance.

The reported results provide visibility into the underlying data quality rather than only a binary pass/fail outcome.

---

# Recommended Pipeline Flow

The raw-layer DQ validation forms part of the Medallion Architecture:

```text
Raw Source Files
      |
      v
+----------------+
|    01-raw      |
|                |
| OULAD Tables   |
+----------------+
      |
      v
+----------------+
| Raw DQ Checks  |
|                |
| Completeness   |
| Uniqueness     |
| Validity       |
| Referential    |
| Integrity      |
+----------------+
      |
      | PASS
      v
+----------------+
|   02-clean     |
|                |
| Standardize    |
| Clean          |
| Transform      |
+----------------+
      |
      v
+----------------+
|   03-mart      |
|                |
| Analytics /    |
| Reporting      |
+----------------+
```

---

# Conclusion

The final raw-layer Data Quality assessment produced **59 passing checks out of 59**, resulting in a **100% DQ pass rate**.

The validation also identified **0 orphan references** across the tested relationships.

The results indicate that the raw OULAD dataset satisfies the defined completeness, uniqueness, validity, and referential-integrity criteria. The dataset can therefore proceed to the clean/silver layer for subsequent standardization and transformation.
