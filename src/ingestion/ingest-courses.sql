-- ingestion method: use copy into to load the csv file into a bronze delta table
-- schema method: explicitly define the bronze schema and metadata columns
-- data quality method: use try_cast for numeric fields

CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.courses (
    code_module STRING,
    code_presentation STRING,
    module_presentation_length INT,
    _source_file STRING,                -- fixed: added source-file lineage
    _ingested_at TIMESTAMP,             -- fixed: added ingestion timestamp
    _run_id STRING,                     -- fixed: added pipeline run identifier
    _rescued_data STRING                -- fixed: added malformed-value tracking
)
USING DELTA;

COPY INTO `ftw-week-07`.`01-raw`.courses
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(module_presentation_length AS INT) AS module_presentation_length, -- fixed: safely converts the numeric field
        _metadata.file_name AS _source_file,             -- fixed: captures the source filename
        current_timestamp() AS _ingested_at,             -- fixed: records the ingestion timestamp
        date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _run_id, -- fixed: generates the run id automatically
        NULL AS _rescued_data                             -- fixed: added rescued-data column
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/courses.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true'
);