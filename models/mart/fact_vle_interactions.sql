{{ config(alias='fact_vle_interactions') }}

select
  sha2(
    concat_ws(
      '||', interaction.code_module, interaction.code_presentation,
      cast(interaction.id_student as string), cast(interaction.id_site as string),
      cast(interaction.activity_date as string)
    ),
    256
  ) as vle_interaction_key,
  sha2(cast(interaction.id_student as string), 256) as student_key,
  sha2(interaction.code_module, 256) as course_key,
  sha2(concat_ws('||', interaction.code_module, interaction.code_presentation), 256)
    as module_presentation_key,
  sha2(
    concat_ws(
      '||', coalesce(student.gender, 'UNKNOWN'), coalesce(student.region, 'UNKNOWN'),
      coalesce(student.highest_education, 'UNKNOWN'), coalesce(student.imd_band, 'UNKNOWN'),
      coalesce(student.age_band, 'UNKNOWN'), coalesce(student.disability, 'UNKNOWN')
    ),
    256
  ) as demographics_key,
  sha2(cast(interaction.activity_date as string), 256) as activity_date_id,
  cast(interaction.id_site as bigint) as id_site,
  activity.activity_type,
  cast(interaction.sum_click as bigint) as sum_click
from {{ source('oulad_clean', 'student_vle_clean') }} as interaction
inner join {{ source('oulad_clean', 'vle_clean') }} as activity
  on interaction.code_module = activity.code_module
  and interaction.code_presentation = activity.code_presentation
  and interaction.id_site = activity.id_site
inner join {{ source('oulad_clean', 'student_info_clean') }} as student
  on interaction.code_module = student.code_module
  and interaction.code_presentation = student.code_presentation
  and interaction.id_student = student.id_student
