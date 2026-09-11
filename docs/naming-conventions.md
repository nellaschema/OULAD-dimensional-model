# Naming conventions

| Object | Convention | Example |
|---|---|---|
| Physical dimension | `dim_` + singular entity | `dim_module_presentation` |
| Fact | `fact_` + plural required process | `fact_assessments` |
| Clean table | Source entity + `_clean` | `student_assessment_clean` |
| Analytics table | Descriptive lower snake case | `student_cohort` |
| Dimension key | `<dimension>_key` | `course_key` |
| Fact primary key | Descriptive event key | `assessment_submission_key` |

Use lowercase `snake_case`. Keep source IDs such as `id_student`,
`id_assessment`, and `id_site` as attributes. Use `_count` and `_sum` for
additive controls, `_rate` for values from zero to one, and `_pct` for values
from zero to 100. Relative offsets use `_relative_day`; they are not calendar
dates.

Canonical core names are:

- `dim_student`
- `dim_course`
- `dim_module_presentation`
- `dim_date`
- `dim_demographics`
- `fact_assessments`
- `fact_vle_interactions`
