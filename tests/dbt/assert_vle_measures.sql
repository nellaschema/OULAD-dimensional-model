-- Purpose: Reject daily VLE facts with zero or negative click totals.
-- Why: Silver retains only positive source interactions and sums repeated rows,
-- so a nonpositive Gold measure signals a broken transformation contract.
-- Pass condition: This query returns zero rows.
select vle_interaction_key
from {{ ref('fact_vle_interactions') }}
where sum_click <= 0
