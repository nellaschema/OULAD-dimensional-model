{{ config(alias='dim_course') }}

select distinct
  sha2(code_module, 256) as course_key,
  code_module
from {{ source('oulad_clean', 'courses_clean') }}
