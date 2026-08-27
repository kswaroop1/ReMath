# ADR 0002: Adaptive fluency scheduling

- Status: Accepted
- Date: 27 August 2026

## Context

A correct answer alone does not show mathematical fluency. ReMath must distinguish
accuracy from speed, revisit weak material, and preserve the ability to rebuild
mastery when the algorithm changes.

## Decision

For foundation arithmetic, classify every attempt as:

- incorrect;
- correct but slower than the operation target; or
- fluent: correct within the operation target.

Addition and subtraction initially target six seconds; multiplication targets
eight seconds. These are algorithm parameters, not claims of universal mastery,
and will later be calibrated from content difficulty and learner evidence.

Each new observation updates its operation score using 70% previous evidence and
30% new evidence. An incorrect attempt contributes 0, a slow correct attempt 0.6,
and a fluent attempt 1.0. Scores are derived, never authoritative stored state.

The scheduler:

1. introduces each unattempted operation;
2. selects due skills before skills whose review is scheduled later;
3. chooses the lowest-scoring candidate with stable operation order as a tie
   breaker;
4. schedules incorrect attempts immediately, slow attempts after five minutes,
   and fluent streaks after one hour, one day, three days, then seven days.

## Consequences

- Accuracy and fluency remain distinct.
- The same immutable attempts rebuild the same score on every device.
- Algorithm changes can be versioned later without migrating personal history.
- Initial thresholds and intervals need empirical calibration.
- This policy covers foundation arithmetic only; symbolic work and advanced
  problem solving will need richer evidence models.
