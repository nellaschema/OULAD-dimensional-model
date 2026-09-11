select vle_interaction_key
from {{ ref('fact_vle_interactions') }}
where sum_click <= 0
