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
