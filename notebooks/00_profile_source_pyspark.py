# Databricks notebook source
"""Optional PySpark source profile for the seven OULAD CSV files.

This notebook is diagnostic only. The production Bronze load remains the
idempotent SQL path in src/01_bronze/sql/02_bronze_sources.sql.
"""

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.types import (
    DecimalType,
    IntegerType,
    LongType,
    StringType,
    StructField,
    StructType,
)

SOURCE_PATH = "/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07"

SOURCES = {
    "courses": (
        StructType([
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("module_presentation_length", IntegerType()),
        ]),
        ["code_module", "code_presentation"],
    ),
    "assessments": (
        StructType([
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("id_assessment", LongType()),
            StructField("assessment_type", StringType()),
            StructField("date", IntegerType()),
            StructField("weight", DecimalType(7, 3)),
        ]),
        ["id_assessment"],
    ),
    "vle": (
        StructType([
            StructField("id_site", LongType()),
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("activity_type", StringType()),
            StructField("week_from", IntegerType()),
            StructField("week_to", IntegerType()),
        ]),
        ["code_module", "code_presentation", "id_site"],
    ),
    "studentInfo": (
        StructType([
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("id_student", LongType()),
            StructField("gender", StringType()),
            StructField("region", StringType()),
            StructField("highest_education", StringType()),
            StructField("imd_band", StringType()),
            StructField("age_band", StringType()),
            StructField("num_of_prev_attempts", IntegerType()),
            StructField("studied_credits", IntegerType()),
            StructField("disability", StringType()),
            StructField("final_result", StringType()),
        ]),
        ["code_module", "code_presentation", "id_student"],
    ),
    "studentRegistration": (
        StructType([
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("id_student", LongType()),
            StructField("date_registration", IntegerType()),
            StructField("date_unregistration", IntegerType()),
        ]),
        ["code_module", "code_presentation", "id_student"],
    ),
    "studentAssessment": (
        StructType([
            StructField("id_assessment", LongType()),
            StructField("id_student", LongType()),
            StructField("date_submitted", IntegerType()),
            StructField("is_banked", IntegerType()),
            StructField("score", DecimalType(7, 3)),
        ]),
        ["id_assessment", "id_student"],
    ),
    "studentVle": (
        StructType([
            StructField("code_module", StringType()),
            StructField("code_presentation", StringType()),
            StructField("id_student", LongType()),
            StructField("id_site", LongType()),
            StructField("date", IntegerType()),
            StructField("sum_click", LongType()),
        ]),
        ["code_module", "code_presentation", "id_student", "id_site", "date"],
    ),
}

# COMMAND ----------

summary_rows = []

for source_name, (schema, grain_columns) in SOURCES.items():
    frame = (
        spark.read.format("csv")
        .option("header", "true")
        .option("nullValue", "?")
        .option("mode", "FAILFAST")
        .schema(schema)
        .load(f"{SOURCE_PATH}/{source_name}.csv")
    )
    total_rows = frame.count()
    distinct_grain_rows = frame.select(*grain_columns).distinct().count()
    missing_grain_rows = frame.filter(
        F.greatest(*[F.col(column).isNull().cast("int") for column in grain_columns]) == 1
    ).count()
    summary_rows.append(
        (source_name, total_rows, distinct_grain_rows, total_rows - distinct_grain_rows, missing_grain_rows)
    )

profile = spark.createDataFrame(
    summary_rows,
    ["source_name", "row_count", "distinct_grain_rows", "repeated_grain_rows", "missing_grain_rows"],
)

display(profile.orderBy(F.desc("row_count")))
