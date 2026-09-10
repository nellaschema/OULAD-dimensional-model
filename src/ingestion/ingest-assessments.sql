-- ingestion method:    use copy into for idempotent csv ingestion from the unity catalog volume into bronze delta tables
-- schema handling:     explicitly define the bronze schema and use try_cast for safe type conversion
-- data quality:        preserve malformed source values in _rescued_data instead of silently discarding them
-- lineage:             capture the source filename, ingestion timestamp, and run id for every ingested row

-- ingest assessments.csv
CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.assessments (
    code_module STRING,
    code_presentation STRING,
    id_assessment INT,
    assessment_type STRING,
    date INT,
    weight DOUBLE,
    _source_file STRING,       -- fixed: added source-file metadata
    _ingested_at TIMESTAMP,    -- fixed: added ingestion timestamp metadata
    _run_id STRING,            -- fixed: added pipeline-run metadata
    _rescued_data STRING       -- fixed: added quarantine column for malformed values
) USING DELTA;

COPY INTO `ftw-week-07`.`01-raw`.assessments
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(id_assessment AS INT) AS id_assessment,
        assessment_type,
        TRY_CAST(date AS INT) AS date,
        TRY_CAST(weight AS DOUBLE) AS weight,
        _metadata.file_name AS _source_file,       -- fixed: captures the actual source file name
        current_timestamp() AS _ingested_at,       -- fixed: records when the row was ingested
        date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _run_id,                     -- fixed: records the pipeline run identifier
        CASE
            WHEN id_assessment IS NOT NULL
                 AND TRY_CAST(id_assessment AS INT) IS NULL
            THEN to_json(named_struct('id_assessment', id_assessment))
            WHEN date IS NOT NULL
                 AND TRY_CAST(date AS INT) IS NULL
            THEN to_json(named_struct('date', date))
            WHEN weight IS NOT NULL
                 AND TRY_CAST(weight AS DOUBLE) IS NULL
            THEN to_json(named_struct('weight', weight))
            ELSE NULL
        END AS _rescued_data                         -- fixed: preserves values that failed type conversion
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/assessments.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true',
    'inferSchema' = 'false'
);

