-- Purpose: Reject assessment facts with an observed score or weight outside 0-100.
-- Why: Generic dbt schema tests cover keys, but these numeric business ranges
-- require a row-level predicate. Null score is intentionally allowed by source.
-- Pass condition: This query returns zero rows.
select assessment_submission_key
from {{ ref('fact_assessments') }}
where score not between 0 and 100
   or assessment_weight not between 0 and 100
