#!/usr/bin/env python3
"""Dependency-free structural checks for the OULAD repository."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "README.md",
    ".gitignore",
    "dbt_project.yml",
    "profiles.yml.example",
    "requirements-dbt.txt",
    "models/staging/sources.yml",
    "models/mart/schema.yml",
    "models/mart/dim_student.sql",
    "models/mart/dim_course.sql",
    "models/mart/dim_module_presentation.sql",
    "models/mart/dim_date.sql",
    "models/mart/dim_demographics.sql",
    "models/mart/fact_assessments.sql",
    "models/mart/fact_vle_interactions.sql",
    "metabase/README.md",
    "metabase/dashboard_queries.sql",
    "metabase/data_quality_dashboard_queries.sql",
    "notebooks/00_profile_source_pyspark.py",
    "notebooks/06_run_after_dbt.sql",
    "dashboard/oulad-analytics-dashboard.md",
    "dashboard/oulad-data-quality-dashboard.md",
    "src/00_setup/01_setup.sql",
    "src/01_bronze/sql/02_bronze_sources.sql",
    "src/02_silver/sql/04_silver_tables.sql",
    "src/03_gold/sql/05_reset_gold_model.sql",
    "src/03_gold/sql/06_gold_dimensions.sql",
    "src/03_gold/sql/07_gold_facts.sql",
    "src/03_gold/sql/08_gold_relationships.sql",
    "src/04_analytics/sql/09_learner_outcomes.sql",
    "src/04_analytics/sql/10_student_engagement.sql",
    "src/04_analytics/sql/11_assessment_performance.sql",
    "src/04_analytics/sql/12_at_risk_students.sql",
    "src/05_data_quality/sql/14_dq_dashboard_views.sql",
    "tests/03_validate_bronze.sql",
    "tests/05_validate_silver.sql",
    "tests/08_validate_gold.sql",
    "tests/13_validate_analytics.sql",
    "docs/assets/final-star-schema.svg",
    "docs/data-model.md",
    "docs/pipeline.md",
    "docs/data-quality-methodology.md",
    "docs/validation.md",
    # Original group queries are deliberately retained alongside the new path.
    "src/ingestion/ingestion.sql",
    "src/cleaning/cleaning.sql",
    "src/data-quality/raw-data-quality-check.sql",
    "src/mart/dim_course.sql",
    "src/mart/dim_date.sql",
    "src/mart/dim_demographics.sql",
    "src/mart/dim_module_presentation.sql",
    "src/mart/dim_student.sql",
    "src/mart/fact_assessments.sql",
    "src/mart/fact_vle_interactions.sql",
    "src/mart/supp_student_cohort.sql",
)

FULL_RUNNER_TARGETS = (
    "src/00_setup/01_setup.sql",
    "src/01_bronze/sql/02_bronze_sources.sql",
    "tests/03_validate_bronze.sql",
    "src/02_silver/sql/04_silver_tables.sql",
    "tests/05_validate_silver.sql",
    "src/03_gold/sql/05_reset_gold_model.sql",
    "src/03_gold/sql/06_gold_dimensions.sql",
    "src/03_gold/sql/07_gold_facts.sql",
    "tests/08_validate_gold.sql",
    "src/03_gold/sql/08_gold_relationships.sql",
    "src/04_analytics/sql/09_learner_outcomes.sql",
    "src/04_analytics/sql/10_student_engagement.sql",
    "src/04_analytics/sql/11_assessment_performance.sql",
    "src/04_analytics/sql/12_at_risk_students.sql",
    "tests/13_validate_analytics.sql",
    "src/05_data_quality/sql/14_dq_dashboard_views.sql",
)

SQL_GLOBS = (
    "src/**/*.sql",
    "tests/**/*.sql",
    "queries/**/*.sql",
    "dashboards/**/*.sql",
    "oulad-genie-pack/**/*.sql",
    "models/**/*.sql",
    "metabase/**/*.sql",
)

PRESERVED_TEAM_SQL_PREFIXES = (
    "src/ingestion/",
    "src/cleaning/",
    "src/mart/",
    "src/data-quality/",
    "tests/cleaning-validation.sql",
)


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        if not (ROOT / relative_path).is_file():
            errors.append(f"missing required file: {relative_path}")

    for markdown in ROOT.rglob("*.md"):
        if ".git" in markdown.parts:
            continue
        for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", markdown.read_text(encoding="utf-8")):
            local_target = target.split("#", 1)[0].strip().strip("<>")
            if not local_target or re.match(r"^[a-z][a-z0-9+.-]*:", local_target, re.IGNORECASE):
                continue
            if not (markdown.parent / local_target).resolve().exists():
                errors.append(
                    f"broken local Markdown link in {markdown.relative_to(ROOT)}: {target}"
                )

    sql_files = sorted(
        {
            path
            for pattern in SQL_GLOBS
            for path in ROOT.glob(pattern)
            if path.is_file()
        }
    )

    for path in sql_files:
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(ROOT)
        if not text.strip():
            errors.append(f"empty SQL file: {relative_path}")
        if str(relative_path).startswith(PRESERVED_TEAM_SQL_PREFIXES):
            continue
        if re.search(r"\bTODO\b", text, re.IGNORECASE):
            errors.append(f"unfinished TODO marker: {relative_path}")
        if re.search(r"\bSELECT\s+\*\b", text, re.IGNORECASE):
            errors.append(f"unqualified SELECT star: {relative_path}")
        if re.search(r"\bDECLARE\s+(?:VARIABLE\s+)?IF\s+NOT\s+EXISTS\b", text, re.IGNORECASE):
            errors.append(f"unsupported Databricks variable declaration: {relative_path}")

    runner = ROOT / "notebooks/00_run_full_pipeline.sql"
    if not runner.is_file():
        errors.append("missing full pipeline runner")
    else:
        runner_text = runner.read_text(encoding="utf-8")
        last_position = -1
        for target in FULL_RUNNER_TARGETS:
            notebook_path = "../" + target.removesuffix(".sql")
            position = runner_text.find(f"%run {notebook_path}")
            if position < 0:
                errors.append(f"full runner does not invoke: {target}")
            elif position <= last_position:
                errors.append(f"full runner target is out of order: {target}")
            last_position = max(last_position, position)

    assessment_sql = ROOT / "src/04_analytics/sql/11_assessment_performance.sql"
    if assessment_sql.is_file():
        text = assessment_sql.read_text(encoding="utf-8")
        for required_column in (
            "scored_submission_count",
            "missing_score_count",
            "score_sum",
            "passed_submission_count",
            "dated_submission_count",
            "late_submission_count",
        ):
            if required_column not in text:
                errors.append(f"assessment controls missing: {required_column}")

    relationship_run = "%run ../src/03_gold/sql/08_gold_relationships"
    for notebook_name in (
        "notebooks/00_run_full_pipeline.sql",
        "notebooks/03_gold_oulad.sql",
        "notebooks/06_run_after_dbt.sql",
    ):
        notebook = ROOT / notebook_name
        if notebook.is_file() and relationship_run not in notebook.read_text(encoding="utf-8"):
            errors.append(f"relationship registration missing after Gold validation: {notebook_name}")

    professor_models = {
        "dimensions": {
            "dim_student",
            "dim_course",
            "dim_module_presentation",
            "dim_date",
            "dim_demographics",
        },
        "facts": {"fact_assessments", "fact_vle_interactions"},
    }
    model_sql = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (
            ROOT / "src/03_gold/sql/06_gold_dimensions.sql",
            ROOT / "src/03_gold/sql/07_gold_facts.sql",
        )
        if path.is_file()
    ).lower()
    for model_group, models in professor_models.items():
        for model in models:
            if f".{model}'" not in model_sql:
                errors.append(f"missing required {model_group[:-1]} model: {model}")

    legacy_gold_models = (
        "fact_student_enrollment",
        "fact_assessment_submission",
        "fact_vle_interaction",
        "dim_assessment",
        "dim_vle_activity",
        "dim_relative_date",
    )
    for legacy_model in legacy_gold_models:
        if f"create or replace table identifier(mart_namespace || '.{legacy_model}')" in model_sql:
            errors.append(f"legacy Gold model is still created: {legacy_model}")

    dbt_mart_models = {
        path.stem
        for path in (ROOT / "models/mart").glob("*.sql")
        if path.is_file()
    }
    expected_dbt_models = professor_models["dimensions"] | professor_models["facts"]
    if dbt_mart_models != expected_dbt_models:
        errors.append(
            "dbt mart models must be exactly the five required dimensions and two required facts"
        )

    demographic_key_models = (
        ROOT / "models/mart/dim_demographics.sql",
        ROOT / "models/mart/fact_assessments.sql",
        ROOT / "models/mart/fact_vle_interactions.sql",
        ROOT / "src/03_gold/sql/06_gold_dimensions.sql",
        ROOT / "src/03_gold/sql/07_gold_facts.sql",
    )
    for model in demographic_key_models:
        if model.is_file() and "final_result" in model.read_text(encoding="utf-8"):
            errors.append(
                f"enrollment outcome leaked into Gold demographic grain: {model.relative_to(ROOT)}"
            )

    cohort_model = ROOT / "src/04_analytics/sql/09_learner_outcomes.sql"
    if cohort_model.is_file():
        cohort_text = cohort_model.read_text(encoding="utf-8")
        for required_field in ("student_cohort_key", "final_result", "is_withdrawn"):
            if required_field not in cohort_text:
                errors.append(f"student_cohort field missing: {required_field}")

    for dashboard in sorted((ROOT / "dashboards").glob("*.lvdash.json")):
        try:
            json.loads(dashboard.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"invalid dashboard JSON {dashboard.name}: {error}")

    all_text = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in ROOT.rglob("*")
        if path.is_file() and ".git" not in path.parts
    )
    bad_volume_token = "cloudfare" + "-r2"
    if bad_volume_token in all_text:
        errors.append(f"misspelled source volume path: {bad_volume_token}")
    if "genie_" in (ROOT / "metabase/data_quality_dashboard_queries.sql").read_text(encoding="utf-8"):
        errors.append("Metabase DQ queries depend on optional Genie views")

    if errors:
        print("Repository checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Repository checks passed ({len(sql_files)} SQL files inspected).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
