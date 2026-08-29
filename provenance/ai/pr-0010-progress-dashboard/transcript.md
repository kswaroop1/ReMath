# PR 10 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Selection

### User

> i merged it

### Assistant

Codex verified that PR #9 was merged and identified PR #10—progress dashboard
and skill history—as the next recorded roadmap item.

### User

> go ahead

### Assistant

Codex committed to implement PR #10 fully through strict business-focused TDD,
near-100% meaningful coverage, documentation, provenance, and GitHub CI.

### User

> continue

### Assistant

Codex confirmed the scope: an explainable, offline view of attempts, accuracy,
fluency, assistance, retention, and the reasons progress changed, with
foundations for separate knowledge mastery, performance mastery, and forgetting
risk.

## Acceptance criteria

- Coached corrections and hints are visible as assistance but excluded from
  independent accuracy and mastery.
- Each arithmetic skill explains its independent evidence, accuracy, fluency,
  retention state, next review, and knowledge/performance indicators.
- Forgetting risk increases as review approaches, reaches its maximum when
  overdue, and is absent when there is no evidence.
- Skill history explains the effect of every immutable attempt event.
- Empty and partial progress remain honest and deterministic offline.

## Red–green implementation record

### Explainable progress domain — red

Codex first added business examples requiring an honest empty state, strict
separation of assistance from independent evidence, separate knowledge and
performance indicators, increasing forgetting risk, lapse explanations, and
deterministic history. The local environment did not contain Flutter (`flutter:
command not found`), so the intended missing-domain failure is delegated to the
unchanged GitHub CI environment and will be recorded below before production
implementation is published.

GitHub CI run 33259649391 was started against the test-only commit. Codex then
implemented a pure-Dart calculator which derives every dashboard value and
history explanation from immutable attempt events; it introduces no persistence
or network dependency.

### Learner dashboard and history journey — red

Codex next added widget journeys requiring an explicit progress entry point, an
honest empty dashboard, separate skill measures, due-review language, and a
drill-down history containing fluent, incorrect, and assisted events. These
tests precede the controller and UI behavior that will satisfy them.

Codex then connected the derived progress model to the learning controller and
added responsive offline dashboard and history views. The screens expose honest
empty states, practice time, independent/assisted counts, knowledge and
performance indicators, retention, review risk, and an explanation for every
recorded event.

### Canonical formatting diagnosis

Implementation CI runs 33259760954 and 33259949305 stopped at the formatter.
Because Flutter was unavailable locally, Codex temporarily made CI print the
canonical formatter diff in run 33260041746. The resulting changes were applied
verbatim, the permanent non-mutating format gate was restored, and Flutter
3.47's generated analyzer exclusion for `build/**` was retained to prevent
`flutter pub get` from dirtying the checkout.

CI run 33260184904 then passed formatting, fatal analysis, content validation,
and secret scanning before exposing three domain expectation mismatches and a
regression where the new home action displaced the primary drill action below
the default test viewport. Codex preserved the business expectations: exact
full mastery is normalized to 100%, due language explicitly says overdue,
ordinary failed answers remain ordinary answers in history, and the secondary
progress action was moved below the primary drill action.

### Coverage refinement

CI run 33260338902 passed all 156 tests and every quality/safety gate at 99.59%
line coverage. A temporary diagnostic in run 33260460500 located six uncovered
learner-facing branches: dashboard back navigation, empty history, minute-scale
practice time, retained/lapsed labels, and an approaching-review risk label.
Codex restored the permanent 90% merge floor and added characterization journeys
asserting those meaningful states, with 100% retained as the engineering target.

### Goal readiness — red

Before finalizing MP-016, Codex compared the implementation with the numbered
feature wording and found that goal readiness was not yet visible on the new
dashboard. A final business test therefore requires the JEE goal to state how
many contributing foundation skills are ready before the production view is
added.
