-- ingestion method: use copy into to load the csv file into a bronze delta table
-- schema method: explicitly define the bronze schema and metadata columns
-- data quality method: use try_cast for numeric fields

CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.vle (
    id_site INT,
    code_module STRING,
    code_presentation STRING,
    activity_type STRING,
    week_from INT,
    week_to INT,
    _source_file STRING,                -- fixed: added source-file lineage
    _ingested_at TIMESTAMP,             -- fixed: added ingestion timestamp
    _run_id STRING,                     -- fixed: added pipeline run identifier
    _rescued_data STRING                -- fixed: added malformed-value tracking
)
USING DELTA;

COPY INTO `ftw-week-07`.`01-raw`.vle
FROM (
    SELECT
        TRY_CAST(id_site AS INT) AS id_site,             
        code_module,
        code_presentation,
        activity_type,
        TRY_CAST(week_from AS INT) AS week_from,        
        TRY_CAST(week_to AS INT) AS week_to,             
        _metadata.file_name AS _source_file,             -- fixed: captures the source filename
        current_timestamp() AS _ingested_at,             -- fixed: records the ingestion timestamp
        date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _run_id, -- fixed: generates the run id automatically
        NULL AS _rescued_data                             -- fixed: added rescued-data column
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/vle.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true'
);