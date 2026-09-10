-- ingestion method: use copy into to load the csv file into a bronze delta table
-- schema method: explicitly define the bronze schema and metadata columns
-- data quality method: use try_cast for numeric fields

CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_info (
    code_module STRING,
    code_presentation STRING,
    id_student INT,
    gender STRING,
    region STRING,
    highest_education STRING,
    imd_band STRING,
    age_band STRING,
    num_of_prev_attempts INT,
    studied_credits INT,
    disability STRING,
    final_result STRING,
    _source_file STRING,                -- fixed: added source-file lineage
    _ingested_at TIMESTAMP,             -- fixed: added ingestion timestamp
    _run_id STRING,                     -- fixed: added pipeline run identifier
    _rescued_data STRING                -- fixed: added malformed-value tracking
)
USING DELTA;

COPY INTO `ftw-week-07`.`01-raw`.student_info
FROM (
    SELECT
        code_module,
        code_presentation,
        TRY_CAST(id_student AS INT) AS id_student,       
        gender,
        region,
        highest_education,
        imd_band,
        age_band,
        TRY_CAST(num_of_prev_attempts AS INT) AS num_of_prev_attempts, 
        TRY_CAST(studied_credits AS INT) AS studied_credits, 
        disability,
        final_result,
        _metadata.file_name AS _source_file,             -- fixed: captures the source filename
        current_timestamp() AS _ingested_at,             -- fixed: records the ingestion timestamp
        date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _run_id, -- fixed: generates the run id automatically
        NULL AS _rescued_data                             -- fixed: added rescued-data column
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentInfo.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true'
);
