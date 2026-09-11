# OULAD source pipeline guide

This directory contains the executable Databricks SQL path from the seven
source CSV files to dashboard-ready models. The numbering is intentional: it
shows the dependency order and leaves space for validation gates between
layers.

## What the pipeline does

The pipeline loads the fixed OULAD homework snapshot, standardizes and
conforms it, builds the professor-required dimensional model, creates reusable
business outputs, and publishes views for a Data Quality dashboard.

The design separates responsibilities:

- **Setup** configures shared locations and fails early when the source folder
  is incomplete or contains an unexpected CSV.
- **Bronze** creates typed, source-aligned Delta copies and retains rescued-data
  and file-lineage fields.
- **Silver** applies business rules, normalizes text, enforces relationships,
  and aggregates repeated VLE records to the declared daily grain.
- **Gold** implements exactly five dimensions and two facts.
- **Analytics** keeps reusable business logic out of dashboard-specific SQL.
- **Data Quality** exposes the latest results and historical trends without
  changing the persisted validation records.

## Build order

| # | File | Depends on | Produces | Why it runs here |
|---:|---|---|---|---|
| 01 | `00_setup/01_setup.sql` | Seven CSVs in the configured Volume | Five schemas and `dq_check_results` | Verifies prerequisites before compute-heavy work starts |
| 02 | `01_bronze/sql/02_bronze_sources.sql` | Setup | Seven Bronze tables | Establishes typed source copies with ingestion lineage |
| 03 | `../tests/03_validate_bronze.sql` | Bronze | Persisted Bronze DQ results | Stops bad source structure before cleaning |
| 04 | `02_silver/sql/04_silver_tables.sql` | Passing Bronze gate | Seven conformed Silver tables | Applies reusable cleaning and relationship rules once |
| 05 | `../tests/05_validate_silver.sql` | Silver | Persisted Silver DQ results | Proves clean grains and references before dimensional modeling |
| 06 | `03_gold/sql/05_reset_gold_model.sql` | Silver | Empty Gold migration target | Removes incompatible legacy Gold objects during a full rebuild |
| 07 | `03_gold/sql/06_gold_dimensions.sql` | Silver | Five dimensions | Builds conformed descriptive entities before facts |
| 08 | `03_gold/sql/07_gold_facts.sql` | Gold dimensions | Two facts | Adds measurable assessment and engagement events at explicit grains |
| 09 | `../tests/08_validate_gold.sql` | Gold models | Persisted Gold DQ results | Verifies keys, measures, references, and control totals |
| 10 | `03_gold/sql/08_gold_relationships.sql` | Passing Gold gate | Catalog PK/FK metadata | Registers only relationships already proved by tests |
| 11 | `04_analytics/sql/09_learner_outcomes.sql` | Silver | Cohort and presentation outcomes | Preserves the full enrollment denominator outside the two-fact Gold core |
| 12 | `04_analytics/sql/10_student_engagement.sql` | Gold and cohort | Student engagement table | Relates VLE behavior to outcomes, including zero-activity students |
| 13 | `04_analytics/sql/11_assessment_performance.sql` | Gold | Assessment summary | Supplies additive controls and presentation/type metrics |
| 14 | `04_analytics/sql/12_at_risk_students.sql` | Gold and cohort | Transparent risk screening | Combines interpretable engagement and assessment signals |
| 15 | `../tests/13_validate_analytics.sql` | Analytics | Persisted Analytics DQ results | Reconciles reporting outputs with their upstream controls |
| 16 | `05_data_quality/sql/14_dq_dashboard_views.sql` | All validation suites | DQ dashboard views | Publishes current and historical quality status |

Use the notebooks in `../notebooks/` to execute this order. The full SQL-only
demonstration uses `00_run_full_pipeline.sql`; the canonical assignment mart is
built by dbt and then completed with `06_run_after_dbt.sql`.

## How the design was chosen

### Full refresh for the homework snapshot

The supplied CSVs are a fixed snapshot, so each transformation uses
`CREATE OR REPLACE`. This makes reruns deterministic and prevents accidental
duplicate appends. A production feed with recurring arrivals would need
incremental ingestion, watermarks, and late-arriving-data handling.

### Explicit schemas and rescued data

CSV inference can change when samples or missing tokens change. Bronze declares
each schema, parses quoted text consistently, converts the OULAD `?` token to
null where applicable, and retains `_rescued_data` so type mismatches remain
visible to validation rather than disappearing silently.

### Relative dates, not calendar dates

OULAD date fields are integer offsets from a module presentation. The source
does not include the exact calendar start date needed for a trustworthy date
conversion, so the model preserves relative days. Negative values are valid
pre-presentation activity. `dim_date` supplies a shared relative-day key and
course-phase labels.

### Five dimensions and two facts

The Gold core follows the assignment exactly:

- Dimensions: Student, Course, Module Presentation, Date, and Demographics.
- Facts: assessment submissions and daily VLE interactions.

Assessment is kept in `fact_assessments`, and VLE resource descriptors are kept
in `fact_vle_interactions`, because neither is one of the five required
dimensions. Both facts connect directly to all five dimensions.

### Identity, demographics, and outcomes

`dim_student` contains stable anonymized identity. `dim_demographics` contains
profile attributes and uses a deterministic hash of those attributes. A final
result is an enrollment outcome—not a demographic attribute—so it lives in
Analytics `student_cohort` at the student + module-presentation grain.

### Deterministic keys

SHA-256 keys are derived from stable business-key components. The same inputs
therefore generate the same keys in dbt, the SQL compatibility build, and
Analytics. Tests verify uniqueness and relationships; the hash itself does not
replace those tests.

### Complete cohort denominators

Students without assessment submissions or VLE activity must still count in
withdrawal and cohort rates. `student_cohort` starts from Silver student
enrollments, while downstream engagement and risk models use left joins and
zero-fill event counts. This avoids survivorship bias from starting with a fact
table.

### Additive metrics before ratios

Analytics tables store counts and sums alongside rates. Dashboards can safely
aggregate the controls and recalculate a rate; averaging precomputed rates
across unequal groups would give a misleading result.

## Expected rerun behavior

- Setup and transformation files are safe for a planned full refresh.
- Bronze, Silver, Gold, and Analytics tables are replaced, not appended.
- DQ results are appended with a new run ID so history remains available.
- Gold reset is intentionally destructive only inside `03-mart`; do not run it
  when historical Gold versions must be retained.
- Critical validation failures stop the next dependent stage. Fix or explain
  the failed rule instead of bypassing the assertion.

See `../tests/README.md` for check formulas, thresholds, pass conditions, and
troubleshooting.

## Preserved team queries

The original classmate contributions are restored and retained under
`ingestion/`, `cleaning/`, `mart/`, and `data-quality/`. They document how the
group first approached ingestion, cleaning, dimensional tables, supplemental
cohorts, and ad hoc checks. They are valuable for contribution history and
comparison, but the numbered folders are the authoritative final execution
path because they include the complete dependency order, corrected grains,
dbt integration, and validation gates.

Do not run an original file and its numbered replacement in the same production
sequence unless deliberately comparing outputs. The mapping is:

| Preserved contribution | Final execution path |
|---|---|
| `ingestion/ingestion.sql` | `01_bronze/sql/02_bronze_sources.sql` |
| `cleaning/cleaning.sql` | `02_silver/sql/04_silver_tables.sql` |
| `mart/dim_*.sql`, `mart/fact_*.sql` | dbt `../models/mart/` or `03_gold/sql/` compatibility build |
| `mart/supp_student_cohort.sql` | `04_analytics/sql/09_learner_outcomes.sql` |
| `mart/cleaning_query.sql` | dbt tests and `../tests/08_validate_gold.sql` |
| `data-quality/raw-data-quality-check.sql` | the four numbered validation suites |
