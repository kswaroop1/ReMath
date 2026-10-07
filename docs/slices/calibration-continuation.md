# Calibrate and continue

Complete the fourth accepted algebra-reasoning increment as one learner-visible
vertical slice spanning immutable evidence, progress interpretation, session
planning, persistence and end-of-chunk controls. No release is included.

## Learner acceptance

- Before an independent answer, a learner may optionally report low, medium or
  high confidence. After feedback, they may optionally report whether the result
  was unsurprising or surprising. Skipping either prompt never blocks study.
- Confidence and surprise survive restart and are attached to the immutable
  attempt that they describe. A calibration summary distinguishes calibrated
  confidence, underconfidence and overconfidence without changing whether the
  mathematical answer was correct.
- A learner may start a two-minute drill, the standard fifteen-minute chunk, or
  a chained study block. The chosen active-time budget survives pause/restart;
  chained blocks continue through another bounded plan rather than becoming an
  unbounded timer.
- At a completed chunk the learner can stop, repeat the completed focus,
  continue its topic, start the most urgent review, or attempt a mixed challenge.
  Every choice creates an explicit resumable plan and preserves prior evidence.
- New application attempts use scoring contract v2 and allow 90 seconds for
  fluent method/assumption/calculation work. Historical score1 application
  evidence continues to replay with its original 20-second threshold; unknown
  scoring versions remain history-only.

## Engineering acceptance

- Extend attempt and SQLite storage additively with a forward-tested migration;
  legacy events decode with absent optional calibration fields.
- Question identity, plan serialization and scoring interpretation remain
  versioned and deterministic. Stored verdicts remain immutable.
- Controller transitions persist atomically and guard duplicate submissions,
  interruption and failed saves. Confidence/surprise cannot attach to hints or a
  different question.
- Add domain, repository, controller and widget tests at the lowest useful seam,
  including invalid calibration values, skipped prompts, migration, restart,
  every completion route and old/new/unknown scoring replay.
- Record separate red and green commits and CI runs in chronological provenance.
