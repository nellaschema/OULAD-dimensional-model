{{ config(alias='fact_assessments') }}

select
  sha2(
    concat_ws('||', cast(submission.id_assessment as string), cast(submission.id_student as string)),
    256
  ) as assessment_submission_key,
  sha2(cast(submission.id_student as string), 256) as student_key,
  sha2(assessment.code_module, 256) as course_key,
  sha2(concat_ws('||', assessment.code_module, assessment.code_presentation), 256)
    as module_presentation_key,
  sha2(
    concat_ws(
      '||', coalesce(student.gender, 'UNKNOWN'), coalesce(student.region, 'UNKNOWN'),
      coalesce(student.highest_education, 'UNKNOWN'), coalesce(student.imd_band, 'UNKNOWN'),
      coalesce(student.age_band, 'UNKNOWN'), coalesce(student.disability, 'UNKNOWN')
    ),
    256
  ) as demographics_key,
  sha2(cast(submission.date_submitted as string), 256) as submission_date_key,
  case
    when assessment.assessment_date is null then null
    else sha2(cast(assessment.assessment_date as string), 256)
  end as due_date_key,
  cast(submission.id_assessment as bigint) as id_assessment,
  assessment.assessment_type,
  cast(assessment.weight as decimal(5, 2)) as assessment_weight,
  cast(submission.is_banked as boolean) as is_banked,
  cast(submission.score as decimal(5, 2)) as score
from {{ source('oulad_clean', 'student_assessment_clean') }} as submission
inner join {{ source('oulad_clean', 'assessments_clean') }} as assessment
  on submission.id_assessment = assessment.id_assessment
inner join {{ source('oulad_clean', 'student_info_clean') }} as student
  on assessment.code_module = student.code_module
  and assessment.code_presentation = student.code_presentation
  and submission.id_student = student.id_student
