# Source profile

The supplied CSV files were profiled before the Gold model was finalized.

| File | Data rows | Modeled grain |
| --- | ---: | --- |
| `courses.csv` | 22 | Module presentation |
| `assessments.csv` | 206 | Assessment |
| `vle.csv` | 6,364 | VLE site within a module presentation |
| `studentInfo.csv` | 32,593 | Student enrollment in a module presentation |
| `studentRegistration.csv` | 32,593 | Student registration in a module presentation |
| `studentAssessment.csv` | 173,912 | Student assessment submission |
| `studentVle.csv` | 10,655,280 | Source interaction record |

The source has 28,785 distinct students. Seventy-two students have demographic differences across enrollment rows, which is why stable student identity and demographics are separate conformed dimensions.

The CSVs use `?` as a missing-value token. Typed Bronze ingestion converts it
to null. The supplied files contain:

| Field | Missing tokens | Treatment |
|---|---:|---|
| `assessments.date` | 11 | Allowed for exams; becomes a null due-date key |
| `studentAssessment.score` | 173 | Preserved and monitored; never imputed |
| `studentInfo.imd_band` | 1,111 | Preserved as unknown demographic context |
| `studentRegistration.date_registration` | 45 | Preserved as unknown |
| `studentRegistration.date_unregistration` | 22,521 | Expected for students who did not unregister |
| `vle.week_from` and `vle.week_to` | 5,243 each | Optional activity availability window |

Non-null scores are constrained to 0 through 100.

Relative offsets may be negative. The earliest assessment submission is day
-11 and the earliest VLE interaction is day -25; both represent valid
pre-presentation activity and are not data errors.

The VLE source has repeated student, module presentation, site, and day combinations. Silver sums `sum_click` across those records, producing 8,459,320 rows at the declared daily fact grain while preserving all 39,605,099 clicks.

No assessment identifier or VLE site reference is orphaned in the supplied snapshot.
