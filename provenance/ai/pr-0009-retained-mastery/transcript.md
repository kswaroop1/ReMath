# PR 9 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Selection

### User

> i merged it

### Assistant

Codex verified PR #8 on `main` and identified the next recorded roadmap item as
PR #9: review chunks and retained mastery.

### User

> go ahead

### Assistant

Codex committed to implement PR #9 fully through strict business-focused TDD,
near-100% meaningful coverage, documentation, provenance, and GitHub CI.

## Acceptance criteria

- Immediate repetition can improve fluency but cannot alone prove retention.
- Correct recall on multiple delayed occasions advances retained mastery.
- A later failure records a lapse and makes the skill immediately due.
- Review selection prioritises overdue skills, then skills approaching review,
  and explains why each item was selected.
- A learner can start and resume a focused 15-minute review chunk offline.
- Review answers remain ordinary immutable mastery evidence.
- Existing schema-v1 through schema-v4 progress data migrates safely.
- Permanent CI retains fatal warnings/infos, secret scanning, and meaningful
  production coverage at or near 100%.

## Red–green implementation record

### Retained-mastery rules — red

Codex first published business tests showing that rapid repetition must count as
one occasion, three on-time delayed successes confirm retention, a later failure
records a lapse, coached work is excluded, and overdue review precedes
approaching review. CI run 33257937508 failed because the retained-mastery domain
did not yet exist.

### Retained-mastery rules — green

Codex implemented the pure-Dart `RetainedMasteryCalculator`. It derives state,
successful occasions, due instants, explanations, and a deterministic review
queue entirely from immutable attempts. CI then reached the formatter gate,
confirming that the missing API had been supplied.

### Review journey and persistence — red

Codex published controller, SQLite, and widget journeys requiring the most
urgent skill to open as a focused review, an empty queue to remain a safe no-op,
an interrupted review and answer draft to resume exactly, schema persistence,
and a learner-facing explanation. CI run 33258081602 failed because the review
session phase and controller/UI behavior did not yet exist.

### Review journey and persistence — green

Codex added a resumable `review` session phase, transactional schema-v5
migration, controller selection and restoration, and the offline review entry
point. Review attempts reuse the immutable answer/correction/retest evidence
path. CI run 33258327988 passed 142 tests with no analyzer issues and measured
99.54% line coverage.

### Coverage and safety refinement

CI run 33258423020 identified exactly six uncovered lines: deterministic tie
ordering and the schema-v5 rollback path. Codex added business cases for
curriculum-order stability, the seven-day retention ceiling, new/due/retained
explanations, schema-v4 session preservation, and transactional rollback. The
temporary diagnostic workflow was then removed.

CI run 33258657115 passed all 147 tests, reported no analyzer issues under fatal
warnings and infos, passed content validation and secret scanning, and measured
100.00% production line coverage.
