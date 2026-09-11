select assessment_submission_key
from {{ ref('fact_assessments') }}
where score not between 0 and 100
   or assessment_weight not between 0 and 100
