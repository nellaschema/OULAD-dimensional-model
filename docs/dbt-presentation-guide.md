# Understanding the dbt Mart

This guide explains how dbt is used in the OULAD project and how to discuss it
during the presentation.

## What is dbt?

dbt stands for **data build tool**. It does not store the data by itself.
Databricks stores and processes the data, while dbt organizes our SQL models,
builds them in the correct order, and tests the results.

In our project, dbt turns the cleaned Silver tables into the final Gold mart.

```text
Silver tables
     ↓
sources.yml
     ↓
dbt SQL models
     ↓
5 dimensions + 2 facts
     ↓
schema.yml and custom tests
     ↓
Validated Gold mart
```

## Why did we use dbt?

Running many SQL files manually can lead to mistakes, such as running them in
the wrong order or forgetting a test. dbt helps us by:

- controlling the order in which tables are built;
- keeping each transformation in a separate SQL model;
- testing keys, values, and table relationships;
- documenting the final tables; and
- rebuilding the mart in a repeatable way.

## What happens when dbt runs?

We run:

```bash
dbt build --select path:models/mart
```

dbt then:

1. Connects to Databricks.
2. Reads the cleaned Silver tables.
3. Builds the dimension tables.
4. Builds the fact tables that depend on those dimensions.
5. Runs the standard and custom tests.
6. Reports an error if a model or test fails.

## Important dbt files

### `dbt_project.yml`

This is the main project configuration file. It tells dbt where the models,
tests, and macros are located and how the output should be created.

Our configuration tells dbt to create physical Delta tables in `03-mart`.

```yaml
models:
  oulad_analytics:
    mart:
      +schema: 03-mart
      +materialized: table
      +file_format: delta
```

**Presentation explanation:**

> The `dbt_project.yml` file controls the whole dbt project. It tells dbt to
> build our mart models as Delta tables inside the `03-mart` schema.

### `profiles.yml.example`

This file shows dbt how to connect to Databricks. It uses these environment
variables:

```text
DATABRICKS_HOST
DATABRICKS_HTTP_PATH
DATABRICKS_TOKEN
```

The real token must not be uploaded to GitHub.

**Presentation explanation:**

> The profile connects dbt to our Databricks SQL warehouse. We use environment
> variables so private credentials are not exposed in the repository.

### `models/staging/sources.yml`

This file declares the cleaned Silver tables that dbt will read, such as
`courses_clean`, `student_info_clean`, and `student_vle_clean`.

A dbt model refers to a declared source using:

```sql
select *
from {{ source('oulad_clean', 'student_info_clean') }}
```

**Presentation explanation:**

> `sources.yml` tells dbt where our cleaned input tables are located. It clearly
> separates existing source tables from the new tables created by dbt.

### `models/mart/*.sql`

These SQL files define the final mart tables:

- `dim_student.sql`
- `dim_course.sql`
- `dim_module_presentation.sql`
- `dim_date.sql`
- `dim_demographics.sql`
- `fact_assessments.sql`
- `fact_vle_interactions.sql`

Each file contains the query used to build one table. Models can refer to other
models with `ref()`:

```sql
from {{ ref('dim_student') }}
```

dbt reads the `ref()` calls to determine the correct build order. For example,
it builds `dim_student` before a fact table that uses it.

**Presentation explanation:**

> Each SQL model builds one final table. The `ref()` function creates a
> dependency, so dbt knows which tables must be built first.

### `models/mart/schema.yml`

This file documents the models and defines standard data tests.

| Test | Meaning |
|---|---|
| `not_null` | A required value cannot be missing |
| `unique` | A key cannot appear more than once |
| `relationships` | A foreign key must exist in its dimension |
| `accepted_values` | A value must belong to an approved list |

Example:

```yaml
- name: student_key
  data_tests:
    - not_null
    - unique
```

**Presentation explanation:**

> `schema.yml` acts as documentation and a data-quality contract. It describes
> the tables and lists the rules that their columns must pass.

### `macros/generate_schema_name.sql`

A macro is a reusable function made with SQL and Jinja. Our macro changes dbt's
normal schema-naming behavior.

Without the macro, dbt may create a combined name such as:

```text
default_03-mart
```

The macro makes dbt use the required name exactly:

```text
03-mart
```

**Presentation explanation:**

> A macro is similar to a reusable function. Our macro ensures that dbt creates
> the output in the exact `03-mart` schema required by the assignment.

### `tests/dbt/*.sql`

These are custom tests for business rules that cannot be fully covered by the
standard YAML tests. They check that:

- assessment scores and weights are within valid ranges;
- VLE click totals are positive; and
- the course in each fact agrees with its module presentation.

A custom dbt test passes when its query returns **zero rows**. Any returned row
represents a problem.

**Presentation explanation:**

> Our custom tests check project-specific rules. Zero returned rows means no
> invalid records were found.

### `requirements-dbt.txt`

This file lists `dbt-databricks`, the adapter that allows dbt to communicate
with Databricks.

**Presentation explanation:**

> The requirements file makes the setup repeatable by telling every developer
> which dbt package must be installed.

## SQL, YAML, and macros: the difference

| File type | Purpose |
|---|---|
| SQL model | Defines how a table is built |
| YAML file | Configures, documents, and tests models |
| Macro | Reuses or customizes dbt behavior |
| `profiles.yml` | Connects dbt to Databricks |
| `dbt_project.yml` | Controls the complete dbt project |

An easy way to remember this is:

> SQL builds the tables, YAML describes and tests them, and macros customize
> how dbt behaves.

## Our final mart

The mart contains five dimensions and two facts.

| Table | One row represents |
|---|---|
| `dim_student` | One student |
| `dim_course` | One course or module |
| `dim_module_presentation` | One specific course offering |
| `dim_date` | One relative course day |
| `dim_demographics` | One demographic profile |
| `fact_assessments` | One student assessment submission |
| `fact_vle_interactions` | One student's VLE activity on one relative day |

Because the two fact tables share the dimensions, the design is technically a
**galaxy schema**.

## Short presentation script

> Our cleaned Silver tables are declared in `sources.yml`. The SQL files under
> `models/mart` transform those sources into five dimensions and two fact
> tables. We use `ref()` to connect the models, allowing dbt to determine the
> correct build order. The `schema.yml` file documents the tables and tests
> their keys, required values, accepted values, and relationships. Custom SQL
> tests check business-specific rules. Our macro ensures that the output goes
> into the exact `03-mart` schema. Finally, `dbt build` creates the mart and
> runs all tests in one command.

## Common presentation questions

### Is dbt a database?

No. Databricks is the data platform. dbt sends transformation queries to
Databricks and manages how the final tables are built and tested.

### Why not use only normal SQL scripts?

Normal SQL can build the tables, but dbt adds dependency management, automatic
testing, reusable configuration, and documentation.

### What is the purpose of `ref()`?

It refers to another dbt model and creates a dependency. This lets dbt build
the tables in the correct order.

### What is the purpose of `source()`?

It refers to an existing input table that dbt does not create, such as a Silver
table in Databricks.

### How do we know the mart is correct?

The mart must pass standard YAML tests, custom SQL tests, and the final Gold
validation notebook before Analytics is refreshed.
