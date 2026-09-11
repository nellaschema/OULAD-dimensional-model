{{ config(alias='dim_module_presentation') }}

select
  sha2(concat_ws('||', code_module, code_presentation), 256)
    as module_presentation_key,
  sha2(code_module, 256) as course_key,
  code_module,
  code_presentation,
  cast(module_presentation_length as int) as module_presentation_length
from {{ source('oulad_clean', 'courses_clean') }}
