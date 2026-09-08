# Chronological implementation record

## User scope

User: "Lets skip the release for now.  How big are these two features ma-001 and 2?  Can ww be a bit more ambitious and do a larger feature set?  Remember we were vertical slicing the features and incrementally adding core infra features."

Assistant proposed a number-fluency/proportional-reasoning vertical slice, followed
later by an algebra bridge. After a core feature status inventory, the assistant
recommended goal selection, chunk planning, generalised skill progression, MCQs
and complete session resume alongside the number content.

User: "Ok go ahead implement"

## Initial decisions

Fresh clone of merged main e305b3f avoids unrelated modifications in an earlier
workspace. Scope and acceptance were committed before implementation. Existing
arithmetic is operation-specific; the new journey will use generic skill IDs and
reuse exact marking, immutable events, and retained mastery. Legacy drills and
sessions remain accessible. No release and no new external dependencies.

Direct git push lacked credentials. Connected GitHub app created draft PR13;
local test-first history will be mirrored through Git objects in the same order.
Flutter stable was cloned to scratch for local verification. Routine download
telemetry omitted. No hidden reasoning or credentials are included.

## Cycle 1: authored curriculum and deterministic questions

Test-first contract covers all offered skills, exact division, fraction marking,
unique misconception-labelled choices, staged hints and invalid identities.

Red evidence: CI run 34163779871, job 101870701307, passed formatting and failed
analysis because number_curriculum.dart and NumberCurriculum did not exist.
This is the necessary public seam introduced by the contract test. Earlier runs
34163553843/34163663175 were formatting failures, not behavioural red evidence.
Local formatter needed --language-version=3.10 to match the package minimum.
Local Flutter JIT exited 255; an AOT tool attempt was rejected by automatic review
because startup contacted cloud metadata. That runner was abandoned. CI is the
verification authority; no local test success is claimed.

Green implementation: original eleven-skill catalogue, two goals, three bounded
question levels, exact existing numeric markers, four deterministic choices,
four hints and immutable versioned question identity. No dependencies added.

Cycle 1 verification: run 34163961997 reported directives_ordering in the test.
Import order corrected without changing assertions. Run 34164069533 then passed
analysis, the full test suite and coverage enforcement: 99.94% line coverage.

## Cycle 2: goal planning, skill evidence and session serialization

Test-first rules cover independent numeric progression, assistance/MCQ exclusion
from difficulty promotion, difficulty reduction after errors, delayed retention,
review priority, prerequisite advice without blocking exploration, diagnostic
sampling, and round-trip persistence of a complete plan and interrupted session.

Cycle 2 red: run 34164204564 failed analysis for the missing study_plan.dart
public seam. Implemented generic per-skill evidence, advisory prerequisite
selection, due-review priority, two goal plans and independently sampled
diagnostics. Frozen versioned JSON state preserves question and interaction
identity. Numeric success is required for difficulty and delayed retention;
MCQ accuracy is displayed but cannot establish these claims alone.

Run 34164411157 reported constructor ordering and a missing conditional block.
Corrected in local 46bbf0c; publication was blocked by an exhausted credit limit.
No complete implementation or successful planner verification was claimed.

## Resumption — 8 September 2026

User: "We had run out of credits, pl continue now."

Confirmed PR13 still at the planner implementation commit and published the
pending style correction. Preserved uncommitted storage/controller/widget tests.
Found that the lapse test's observation time preceded its simulated errors by
four seconds. Corrected the fixture to observe after both errors, retaining all
assertions; production review timing is not changed to satisfy that fixture.

Cycle 2 green: run 34190317766 passed analysis/full tests with 98.41% coverage.
Coverage is below cycle 1 because new planner/state branches need additional
boundary tests; this remains an explicit final verification item.

## Cycle 3: atomic persistence

Test-first repository contracts exercise memory and SQLite implementations,
duplicate delivery without state rewind, rollback on a forced write failure,
and schema-five upgrade preserving old attempts and active drafts. Existing
successful migration expectations advance to schema six; failure expectations
remain unchanged.

Cycle 3 red: run 34190464303 failed for the three missing repository methods.
Implemented schema-six study state and atomic attempt/state writes. SQLite's
transaction body is synchronous (no await while the transaction is open).
Duplicates do not rewind the saved state. The legacy repository test double
forwards the new interface methods without changing its existing blocking rule.

Cycle 3 green: run 34190593356 passed all checks, 98.38% line coverage.

## Cycle 4: complete learner session coordination

Test-first scenarios cover goal persistence, exact interrupted question/draft/time,
correction followed by independent retest, persisted hints, invalid input,
duplicate submit, multiple chunks, diagnostic isolation, time expiry, protection
of an unfinished plan, and retry after a persisted write loses acknowledgement.

Cycle 4 red: run 34190708526 failed analysis for the missing StudyController API.
Implementation serializes state writes, guards concurrent submits, restores
committed state on duplicate retries, and records assistance separately. Wrong
practice answers require correction and a fresh numeric retest. Diagnostics
advance without coaching. The timer charges active time only; the ADR explicitly
states the one-second UI-checkpoint limit for an abrupt process kill.

Cycle 4 green: run 34190921363 passed full CI with 98.88% line coverage.

## Cycle 5: uncertain acknowledgement and timer checkpoint

Review found that a timer/pause snapshot could overwrite the already committed
next state after an acknowledgement failure. Extend the existing lost-ack test
with checkpoint and pause before retry; keep the single-event and next-step
assertions. This is a compiling regression test against the current controller.

Cycle 5 red: run 34191117324 passed analysis and failed the compiling recovery
test: expected restored step 1, actual step 0 after checkpoint/pause and retry.
The controller now preserves an uncertain-commit flag and blocks draft/timer/hint
writes until submission retry resolves it. Retry uses the same immutable event
identity and reloads the committed next state when already inserted.

Cycle 5 green: run 34191324869 passed all checks, 98.93% coverage.

## Cycle 6: learner-facing screen

Widget tests first: reach the number journey from the existing home; enter and
correct fractions while retaining focus; persist and submit a selected MCQ;
read the offline lesson and finish a session into the progress overview.

Cycle 6 red: run 34191479615 failed for the missing StudyScreen public seam.
Added the home entry and a responsive scrollable screen with goal choice,
explainable plan, learn/practice/reflection stages, fraction/decimal entry,
selected MCQ state, hint ladder, skill progress/history and pause behaviour.
The UI checkpoints active time every second and persists on lifecycle pause.
The existing drill is preserved, and its home progress refreshes on return.

Run 34191706645: all new number-screen widget tests passed. Existing home tests
failed because the added vertical button moved established controls outside the
viewport. Move navigation into the app bar, preserving the legacy content layout;
no existing test is weakened or changed to accommodate the regression.

Cycle 6 green: run 34191887776 passed all checks, 97.98% coverage. Existing home
interactions and new number flows both pass after the navigation correction.

## Further continuation

User: "We had run out of credits, pl continue now."

Confirmed the remote PR matches the last verified navigation fix; retained the
uncommitted boundary tests. No release has been created.

## Cycle 7: scoring, validation, hints and lifecycle boundaries

Add compiling tests for chance-adjusted MCQ accuracy, invalid persisted state,
independently calculated answers for all generators, explicit worked-solution
steps, and rapid lifecycle pause/resume ordering. The new accuracy getter is an
UnimplementedError public seam in this red commit; it contains no scoring logic.
Other new cases exercise existing behaviour directly, including the suspected
pause/resume race. Independent arithmetic checks characterize existing valid
questions, rather than manufacturing a failure.

Cycle 7 red: after a test-fixture for-loop lint correction, run 34225118851
passed analysis and failed four intended cases: unimplemented chance adjustment,
unknown saved goal accepted, missing intermediate worked calculation, and rapid
resume leaving 15:00 instead of charging five active seconds. Independent prompt
calculation checks passed.

Implement four-choice chance adjustment (wrong choices subtract one third of a
correct-answer unit, clamped to zero), validate saved goals/skills/levels, provide
parameter-specific intermediate hints and solutions, and serialize resume with
pause. Choice results still cannot establish numeric fluency or retention alone.

Cycle 7 green: run 34225499862 passed all checks, 98.33% coverage.

## Final verification coverage

Add characterization widget tests for existing goal navigation, pause/return,
four hints, invalid fraction input, corrupt-state preservation, diagnostic
lifecycle and skill-history explanations. These do not introduce new production
behaviour or manufacture a red result. Coverage reporting now prints uncovered
source lines; threshold calculation and enforcement are unchanged. This is
verification telemetry, not a new product feature.

Run 34225717619 exposed two final-check failures. The invalid-input widget test
found that periodic checkpoints clear its validation message; preserve errors
across checkpoint/pause writes. The lifecycle fixture incorrectly jumped directly
from paused to resumed, violating Flutter's transition assertion. Correct it to
use inactive/hidden/paused/hidden/inactive/resumed, retaining the saved-session
assertion. No production lifecycle rule is changed to accommodate that fixture.

Run 34226317902 passed all checks with 99.64% line coverage after the checkpoint
fix and valid lifecycle fixture. Add existing-behaviour checks for oldest-due
ordering, failed schema-six migration followed by retry, rejection of an unknown
goal without overwriting saved state, and keyboard submission through correction.
These are characterization tests with green-before evidence, not new behaviour.

## Implementation verification and review handoff

Run [34226609046](https://github.com/kswaroop1/ReMath/actions/runs/34226609046)
passed formatting (`dart format --output=none --set-exit-if-changed lib test tool`),
`flutter analyze --fatal-infos --fatal-warnings`, content-pack validation,
`flutter test --coverage`, the unchanged 90% coverage gate, and the secret scan.
Coverage is 99.91%; the merged PR12 base run 34162396702 was 100.00%.
The coverage decrease is exactly two defensive lines:

- `number_curriculum.dart:315`: unknown-generator fallback after catalogue lookup.
  Every fixed catalogue skill has a tested generator; unknown IDs fail the earlier
  lookup. Reaching this fallback would require editing the production catalogue.
- `study_plan.dart:206`: prerequisite-redirection explanation. Both fixed goals
  order every prerequisite before its dependent skill; first-unmastered selection
  therefore already chooses the unmet prerequisite. Explicit exploration remains
  advisory and is tested. This defensive branch supports future catalogue ordering
  but cannot be selected by current goals. No coverage exclusions were added.

The newly reachable boundaries all pass, including migration rollback and retry,
oldest-due ordering, unknown-goal preservation and keyboard submission. No local
Flutter success or real-device validation is claimed; verification ran in CI.

Updated README, feature completion statuses and roadmap to describe the shipped
number-journey scope precisely. MA-001/002 and broader goal/recommendation features
remain partial. The timer has the documented last-unpersisted-checkpoint limit;
atomic answer transitions retain their exact committed state. The algebra bridge
is proposed follow-on work only. No version change, release or merge was made.

Prepare the completed PR for the previously agreed single Codex review request
once the documentation-only head passes CI. Review results are not yet claimed.
