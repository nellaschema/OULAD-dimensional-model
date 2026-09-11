{{ config(alias='dim_student') }}

select distinct
  sha2(cast(id_student as string), 256) as student_key,
  cast(id_student as bigint) as id_student
from {{ source('oulad_clean', 'student_info_clean') }}
