{{ config(alias='dim_date') }}

with source_dates as (
  select assessment_date as relative_day
  from {{ source('oulad_clean', 'assessments_clean') }}
  union all
  select date_submitted
  from {{ source('oulad_clean', 'student_assessment_clean') }}
  union all
  select activity_date
  from {{ source('oulad_clean', 'student_vle_clean') }}
),
date_bounds as (
  select min(relative_day) as minimum_day, max(relative_day) as maximum_day
  from source_dates
  where relative_day is not null
),
relative_days as (
  select explode(sequence(minimum_day, maximum_day)) as relative_day
  from date_bounds
)
select
  sha2(cast(relative_day as string), 256) as date_key,
  cast(relative_day as int) as relative_day,
  cast(floor(relative_day / 7) as int) as relative_week,
  case
    when relative_day < 0 then 'BEFORE PRESENTATION'
    when relative_day <= 28 then 'WEEKS 0-4'
    when relative_day <= 84 then 'WEEKS 5-12'
    when relative_day <= 168 then 'WEEKS 13-24'
    else 'WEEK 25+'
  end as course_phase
from relative_days
