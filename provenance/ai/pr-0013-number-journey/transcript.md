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
