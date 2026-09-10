-- ingestion method: use copy into to load the csv file into a bronze delta table
-- schema method: explicitly define the bronze schema and metadata columns
-- data quality method: use try_cast for numeric fields

CREATE TABLE IF NOT EXISTS `ftw-week-07`.`01-raw`.student_assessment (
    id_assessment INT,
    id_student INT,
    date_submitted INT,
    is_banked INT,
    score DOUBLE,
    _source_file STRING,                -- fixed: added source-file lineage
    _ingested_at TIMESTAMP,             -- fixed: added ingestion timestamp
    _run_id STRING,                     -- fixed: added pipeline run identifier
    _rescued_data STRING                -- fixed: added malformed-value tracking
)
USING DELTA;

COPY INTO `ftw-week-07`.`01-raw`.student_assessment
FROM (
    SELECT
        TRY_CAST(id_assessment AS INT) AS id_assessment, 
        TRY_CAST(id_student AS INT) AS id_student,       
        TRY_CAST(date_submitted AS INT) AS date_submitted, 
        TRY_CAST(is_banked AS INT) AS is_banked,        
        TRY_CAST(score AS DOUBLE) AS score,              
        _metadata.file_name AS _source_file,           
        current_timestamp() AS _ingested_at,             -- fixed: records the ingestion timestamp
        date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _run_id, -- fixed: generates the run id automatically
        NULL AS _rescued_data                             -- fixed: added rescued-data column
    FROM '/Volumes/ftw-week-07/00-source/cloudflare-r2/shared/week07/studentAssessment.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true'
);
