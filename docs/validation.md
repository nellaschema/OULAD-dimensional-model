# Validation reference

| Order | Suite | Main coverage |
|---:|---|---|
| 1 | Bronze | Source contracts, parsing, natural keys, and volume |
| 2 | Silver | Clean grains, domains, relationships, and known null monitoring |
| 3 | Gold | Five dimension keys, two fact grains, direct foreign keys, and measures |
| 4 | Analytics | Cohort/output grains and consolidated cross-layer Accuracy controls |

Gold validation checks all five required dimensions and both required facts.
It also proves that each fact's `course_key` agrees with its module
presentation and that assessment/VLE row counts and totals reconcile to Silver.

Analytics validation confirms:

- complete cohort totals from Silver to `student_cohort` and learner outcomes;
- assessment row, score, and missing-score totals from Silver to Gold to Analytics;
- VLE row and click totals from Silver to Gold and click totals into engagement;
- one engagement and one risk row per cohort member.

Known non-errors include null IMD band, null registration offsets, null exam due
offsets, 173 missing scores, valid negative relative days, and VLE row reduction
caused by intentional daily aggregation.
