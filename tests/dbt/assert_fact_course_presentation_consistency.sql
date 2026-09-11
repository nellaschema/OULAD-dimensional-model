-- Purpose: Verify each fact's direct course key agrees with the course key on
-- its referenced module-presentation dimension.
-- Why: Both keys are intentionally stored on each fact for direct BI joins;
-- ordinary relationship tests prove existence but not agreement between them.
-- Pass condition: This query returns zero rows across both fact tables.
select fact_key
from (
  select
    assessment.assessment_submission_key as fact_key,
    assessment.course_key,
    presentation.course_key as presentation_course_key
  from {{ ref('fact_assessments') }} as assessment
  inner join {{ ref('dim_module_presentation') }} as presentation
    on assessment.module_presentation_key = presentation.module_presentation_key

  union all

  select
    interaction.vle_interaction_key as fact_key,
    interaction.course_key,
    presentation.course_key as presentation_course_key
  from {{ ref('fact_vle_interactions') }} as interaction
  inner join {{ ref('dim_module_presentation') }} as presentation
    on interaction.module_presentation_key = presentation.module_presentation_key
) as facts
where course_key <> presentation_course_key
