# OULAD Raw Data Quality Checks

## 1. Overview

This document describes the Data Quality (DQ) validation performed on the OULAD (Open University Learning Analytics Dataset) tables in the `01-raw` layer.

The validation confirms that the raw data is sufficiently complete, unique, valid, and properly connected before it proceeds to the clean/silver layer.

Four DQ dimensions are evaluated:

1. **Completeness** – identifies missing values.
2. **Uniqueness** – identifies duplicate records based on business keys.
3. **Validity** – verifies expected ranges, domains, and business rules.
4. **Referential Integrity** – identifies orphan records across related tables.

The validation was implemented in Databricks SQL and covers more than **10.8 million rows**.

---

## 2. Dataset Scope

| Table                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| `assessments`          | Assessment definitions, types, dates, and weights |
| `courses`              | Course module and presentation information        |
| `student_assessment`   | Student assessment submissions and scores         |
| `student_info`         | Student demographic and academic information      |
| `student_registration` | Student registration records                      |
| `student_vle`          | Student interactions with VLE activities          |
| `vle`                  | VLE activity definitions                          |

---

## 3. Completeness

Completeness checks identify missing values in required or important columns.

A **0.20% tolerance** is applied to general completeness checks:

```sql
CASE
    WHEN failure_rate <= 0.20 THEN 'PASS'
    ELSE 'FAIL'
END
```

The DQ report records the number of affected rows and the calculated failure rate, even when the result is within the accepted threshold, so that the underlying missingness remains visible.

### Dataset-specific rules

**`assessments.date`**

Some assessment dates are `NULL` for examinations. These are expected based on the OULAD data structure and are therefore excluded from the missing-date check for `Exam` records.

```sql
date IS NULL AND assessment_type <> 'Exam'
```

**`student_assessment.score`**

Missing scores are retained as `NULL` in the raw layer and reported as **WARNING** for explicit handling in the clean/silver layer.

**`student_registration.date_registration`**

Missing registration dates are retained as `NULL` in the raw layer and reported as **WARNING**.

---

## 4. Uniqueness

Duplicate records are checked using the following business keys:

| Table                  | Business Key                                     |
| ---------------------- | ------------------------------------------------ |
| `assessments`          | `id_assessment`                                  |
| `courses`              | `code_module`, `code_presentation`               |
| `student_assessment`   | `id_assessment`, `id_student`                    |
| `student_info`         | `id_student`, `code_module`, `code_presentation` |
| `student_registration` | `id_student`, `code_module`, `code_presentation` |
| `vle`                  | `id_site`                                        |

All defined uniqueness checks passed.

### `student_vle`

The combination `(id_student, id_site, date)` is not treated as a uniqueness key because multiple interactions with the same VLE activity on the same relative day can represent valid records.

---

## 5. Validity

Validity checks verify that values follow the expected OULAD ranges, domains, and business rules.

| Table                  | Validation Rule                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| `assessments`          | `weight` 0–100; `assessment_type` = TMA, CMA, or Exam; populated dates must be valid relative dates |
| `courses`              | `module_presentation_length` > 0                                                                    |
| `student_assessment`   | Populated `score` 0–100; negative `date_submitted` values are allowed as valid relative dates       |
| `student_info`         | `gender` = M/F; `age_band` = `0-35`, `35-55`, `55<=`; `studied_credits` > 0                         |
| `student_registration` | `date_registration` must follow the expected OULAD relative-date representation                     |
| `student_vle`          | `sum_click` > 0; negative `date` values are allowed as valid relative dates                         |
| `vle`                  | `week_from` and `week_to` ≥ 0; `activity_type` must belong to the defined OULAD domain              |

No arbitrary upper limit is applied to OULAD relative-date fields. Negative values are permitted where they are valid according to the dataset structure.

The defined VLE activity types are:

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

All implemented validity checks passed.

---

## 6. Referential Integrity

Referential integrity checks verify that child records have corresponding parent records.

| Child Table            | Parent Table   | Key                                              |
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

A check passes when zero orphan records are found.

**Result: 0 orphan references.**

---

## 7. DQ Validation Query

The complete validation is implemented in the Databricks notebook:

```text
07_01_oulad_raw_data_quality
```

The standardized output contains:

| Column         | Description                 |
| -------------- | --------------------------- |
| `table_name`   | Table being evaluated       |
| `dimension`    | DQ dimension                |
| `check_name`   | Validation rule             |
| `failed_rows`  | Number of affected rows     |
| `total_rows`   | Rows evaluated              |
| `failure_rate` | Percentage of affected rows |
| `status`       | PASS, WARNING, or FAIL      |

---

## 8. Final DQ Results

| Metric                          |             Result |
| ------------------------------- | -----------------: |
| Total Checks                    |                 60 |
| PASS                            |                 58 |
| WARNING                         |                  2 |
| FAIL                            |                  0 |
| Overall DQ Pass Rate            |             96.67% |
| Referential Integrity Pass Rate |               100% |
| Orphan References               |                  0 |
| Dataset Coverage                | 10.8+ million rows |
| Overall Status                  |        **WARNING** |

The two warnings are:

| Table                  | Check                       | Failed Rows | Total Rows | Failure Rate | Status  |
| ---------------------- | --------------------------- | ----------: | ---------: | -----------: | ------- |
| `student_assessment`   | Missing `score`             |         173 |    173,912 |        0.10% | WARNING |
| `student_registration` | Missing `date_registration` |          45 |     32,593 |        0.14% | WARNING |

Both conditions are below the general 0.20% completeness tolerance. They are reported as **WARNING** because the affected values should be explicitly considered during clean/silver processing.

---

## 9. DQ Health Summary

### Completeness

Most completeness checks passed with no missing values.

The two identified conditions are:

* `student_assessment.score`: 173 missing values out of 173,912 rows (0.10%).
* `student_registration.date_registration`: 45 missing values out of 32,593 rows (0.14%).

Both are retained as `NULL` in the raw layer.

Expected missing examination dates are handled separately according to the OULAD data structure.

### Uniqueness

All defined uniqueness checks passed.

No duplicates were identified using the specified business keys.

The `student_vle` table is not evaluated using `(id_student, id_site, date)` as a uniqueness key because repeated interactions can represent legitimate activity.

### Validity

All implemented validity checks passed.

The rules account for OULAD-specific characteristics, including:

* valid negative relative dates,
* expected missing examination dates,
* exact `age_band` values,
* valid assessment score ranges,
* valid VLE activity types, and
* valid ranges for numeric measures.

### Referential Integrity

All referential-integrity checks passed.

No orphan records were detected across the validated relationships.

---

## 10. DQ Rules Summary

| Dimension             | Rule                                                 |
| --------------------- | ---------------------------------------------------- |
| Completeness          | Required IDs: 0 missing                              |
| Completeness          | General checks: ≤ 0.20% missing                      |
| Completeness          | Missing `score`: WARNING                             |
| Completeness          | Missing `date_registration`: WARNING                 |
| Uniqueness            | 0 duplicates using defined business keys             |
| Validity              | Values must follow table-specific ranges and domains |
| Validity              | Negative relative dates are allowed where valid      |
| Referential Integrity | 0 orphan records                                     |

---


## 11. Conclusion

The OULAD raw-layer validation executed **60 DQ checks**, with:

* **58 PASS**
* **2 WARNING**
* **0 FAIL**
* **96.67% overall DQ pass rate**
* **100% referential-integrity pass rate**
* **0 orphan references**

Overall, the raw dataset is **suitable for progression to the clean/silver layer**, with the two documented completeness warnings carried forward for downstream handling.
