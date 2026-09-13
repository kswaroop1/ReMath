# Calibration and continuation

User authorized continuous implementation of the accepted four-increment core
feature programme while independently merging completed PRs. PR18 merged on 12
September after green CI and an independent review reporting no major issues.

Select: define the final increment in docs/slices/calibration-continuation.md
before implementation. It covers optional confidence/surprise evidence,
calibration interpretation, 2/15-minute and chained sessions, explicit completion
routes, and deterministic scoring replay. Open draft PR19 before creating this
provenance directory. No release or merge is authorized for the agent.

Cycle 1 red: new application work must pin scoring v2 with a 90-second fluent
threshold while historical score1 keeps its immutable 20-second interpretation.
Unknown versions remain unsupported. Specify generated identity, fresh-plan
pinning and observable level progression before adding the scoring-version seam.

Cycle 1 red run 34683330874 failed at the intended boundaries: fresh plans
pinned score1 rather than score2, the generator lacked a scoringVersion seam,
and valid 90-second score2 evidence did not advance. Clarify the pre-existing
future-version assertion now that score2 is the selected supported contract;
the branch remains red before production changes.

Cycle 1 first green run 34683560957 exposed two stale test assumptions. A normal
applications plan may correctly start with a non-application prerequisite, so
pinning is asserted on an explicitly selected mixed application plan. The
technique aggregate must count valid score2 evidence once it becomes supported,
changing three-event mean credit to two-thirds. Align those assertions with the
selected contract; no production behavior changes in this correction commit.

Cycle 1 green: run 34683728069 passed the full suite after the aligned
version-two assertions. Cycle 2 select/red: optional low/medium/high confidence
and unsurprising/surprising outcome ratings belong to the immutable attempt.
Independent rated attempts produce an agreement score and explicit calibrated,
overconfident and underconfident counts; assistance and skipped ratings do not
inflate them. SQLite schema v7 must round-trip both optional fields and legacy
migrations must yield null ratings.

Cycle 2 red run 34685132641 failed on the missing calibration model/fields as
intended. The first implementation then exposed two downgrade/retry fixtures
whose tables already contained the newly added columns: schema version was
deliberately rewound while structure remained current. Make the additive v7
migration inspect existing columns so retry is idempotent, while retaining its
transaction and constraints.

Cycle 2 first green run 34685385566 passed all 258 behavior tests, including
migration retries and calibration scoring, but fatal analysis rejected two SQL
string quote styles. Normalize those literals and rerun the full gate.

Cycle 2 green: run 34685497577 passed formatting, analysis and all persistence
and calibration tests. Cycle 3 select/red: selecting confidence on an independent
question must persist through restart, then join the same immutable attempt with
the optional post-feedback surprise rating. Using a hint clears confidence.
Learners who do not select confidence retain the existing one-action submit flow.
Advance the study snapshot to v4 while decoding legacy v1-v3 snapshots.

Cycle 3 red run 34687614402 failed for the absent state confidence, controller
selection/submission seams and snapshot v4; the widget could not find the opt-in
control. Persist confidence in v4, clear it when help is used or a question
advances, and attach it with the dialog's optional surprise in the same atomic
attempt commit. Only opting into confidence adds the post-feedback dialog.

Cycle 3 first green run 34687797810 passed the new controller and calibration
dialog behavior but exposed a compact-height regression: verbose confidence
chip labels pushed the existing MCQ Submit action below an 800×600 viewport.
Shorten the optional row to Low/Medium/High while retaining its heading and
meaning, then rerun all journeys.

Cycle 3 second green run 34687923397 passed all behavior tests after the compact
layout fix, but fatal analysis found two dynamic comparisons on snapshot version.
Cast the decoded schema version once before validation and reuse the typed value.
### Bounded session cycle

After the calibration controls reached green in CI run 34688095449, the next
test-first cycle selected the active-time session contract. Focused controller
and domain tests specify a two-minute drill, the existing fifteen-minute
default, persisted finite chaining metadata, and an atomic transition from a
completed chained chunk into another bounded resumable plan. Production code
has not yet been changed for this behavior.

Red CI run 34691538138 failed at the intended public seams during static
analysis: StudySessionKind and the session/continuation snapshot fields did not
exist, and start did not accept the selected session kind. Implement the
version-5 snapshot with backward-compatible standard defaults, finite chain
metadata, active-time budgets, and persisted chained-plan transition.

The first bounded-session green run 34691688323 passed formatting, analysis,
Chrome contracts, and 264 of 265 native tests. The sole failure was the algebra
journey's explicit snapshot-schema assertion, which correctly observed version
5 rather than its previous version-4 expectation. Align that compatibility
assertion with the additive snapshot version and rerun the full suite.

Bounded-session green rerun 34691863848 passed formatting, static analysis,
265 native tests, seven Chrome tests, and coverage. Select the final learner
workflow cycle: widget acceptance now requires visible two-minute, standard,
and chained entry points; controller acceptance specifies stop, repeat,
continue-topic, urgent-review, and mixed-challenge completion outcomes before
their production seams exist.

Red CI run 34694650100 failed during analysis on the deliberately absent
StudyCompletionChoice API and complete transition; the widget test also names
the missing session entry points. Implement explicit completion planning and
the three start choices, retaining stop as a plan-clearing action and preserving
bounded chained continuation only when the learner chooses continue-topic.

The first completion-workflow green run 34694924821 passed formatting,
analysis, Chrome contracts and all controller route assertions. Its sole native
failure was a widget assertion that required the live two-minute display to
remain exactly 2:00 after asynchronous startup; the correct active timer may
already display 1:59. Keep the exact persisted two-minute budget assertion and
allow either honest initial display.

Completion-workflow rerun 34695098705 passed all 267 native tests, seven Chrome
tests, analysis and coverage. Select the final learner-visible calibration
cycle: a widget test seeds one calibrated, one overconfident and one
underconfident independent answer plus a surprising result, and requires those
counts to appear separately in progress. No presentation seam yet exists.

Red CI run 34699752001 failed solely at the intended widget expectation: no
Confidence calibration heading or categorized counts were rendered. Expose the
existing immutable-history summary through the controller and render it only
when rated evidence exists, separately from mathematical progress.

Final calibration green run 34699939848 passed formatting, zero-diagnostic
analysis, content validation, 268 native tests, seven Chrome tests, and 99.44%
line coverage. The accepted Solve, Explain, Apply, and Calibrate/continue
programme is implementation-complete; update the durable feature register and
roadmap before requesting independent review. No release, merge, or VERSION
change is included.

Independent review of the completed programme found five separate behavioral
boundaries. Rebuild their proof as focused cycles, beginning with chained
continuation: a new bounded block retaining its session ID must also retain the
monotonic event serial so immutable attempt IDs cannot collide.

The first characterization run 34733519210 passed because it exercised the
automatic end-of-block transition, which already preserved the serial. Refine
the test to the distinct learner-selected Continue topic route identified by
review; that route builds a fresh state and is the collision boundary.

Focused chained-route red run 34738552946 failed because Continue topic reset
serial three to zero while retaining the chain session ID. Copy the serial for
finite chained continuation and retain zero only for genuinely new sessions.

Focused chained-route green run 34738707694 passed the full CI suite. Select
the next independent review boundary: time spent reflecting on post-answer
surprise must not inflate the immutable mathematical response-time evidence.

Focused answer-timing red run 34739664232 failed during analysis because the
test deliberately named the absent timing-freeze seam. Persist the elapsed
answer time before showing surprise feedback, pause active timing during the
dialog, and restart timing only after submission or invalid-input recovery.

Focused answer-timing green run 34739788497 passed the full CI suite. Select the
next independent review boundary: imported bounded-session snapshots must not
claim more active time or chained blocks than their advertised session kind.

Focused bounded-import red run 34743442817 failed both new assertions: enlarged
drill time and excessive chained blocks decoded successfully. Enforce each
session kind's maximum budget and finite chain count during encode and decode.

Focused bounded-import green run 34743584553 passed the full CI suite. Select
the next independent review boundary: a completed diagnostic must not expose or
accept ordinary practice continuation routes; only stopping is valid.

Focused diagnostic-completion red run 34743901000 failed because Repeat changed
the completed diagnostic into ordinary practice. Reject every non-stop choice
in the controller and omit those invalid controls from the diagnostic UI.

Focused diagnostic-completion green run 34744027591 passed the full CI suite.
Select the final original review boundary independently: Review what’s due must
include work approaching within 24 hours, while overdue work remains first.

Focused approaching-review red run 34746131046 failed because Review what’s due
created a generic weakest-skill plan rather than selecting the approaching
addition review. Add an explicit review planner that considers overdue and
next-24-hour work, prioritising overdue items before approaching ones.

Focused approaching-review green run 34746261899 passed the full CI suite and
completes reconstruction of the five original findings as independent cycles.
Begin the later edge-case cycles with lifecycle-safe surprise timing: extend
the existing timing regression through pause/resume before the learner records
surprise.
Current resume behavior restarts the answer clock, so this test precedes its
production fix. Subsequent findings will receive separate cycles.

Lifecycle timing red run 34749541236 failed because pause/resume restarted
charging after finishAnswerTiming. Keep a controller-level answer-finished
latch through lifecycle transitions and clear it only when submission either
commits or returns control after invalid input.

Lifecycle timing green run 34749641680 passed the full CI suite. Begin the next
focused cycle: an unsupported future application scoring contract carrying
confidence and surprise must remain history-only and contribute zero
calibration evidence. The controller currently forwards it to the summary.

Supported-calibration red run 34751972819 failed at that intended boundary:
the unsupported application attempt was counted as rated calibration evidence.
Filter learner calibration through the same versioned scoring-support predicate
used by mastery and planning, while retaining unsupported events in history.
The first green run, 34752197017, exposed a missing explicit scoring import at
static analysis; add that compile-time dependency before rerunning verification.

Supported-calibration green run 34754406298 passed the full suite after the
explicit import. Begin the assisted-evidence cycle at both persistence seams:
hint and correction events carrying confidence or surprise must be rejected
before they can enter either in-memory or SQLite history, including atomic
study commits.

Assisted-calibration red run 34754544634 failed because both repositories
accepted the invalid events. Validate the event at every persistence entry
point, before duplicate handling or a SQLite transaction, so hints and
corrections can never persist confidence or surprise evidence.

Assisted-calibration green run 34757586514 passed the full suite. Begin the
legacy-repeat cycle: completing and repeating an imported application plan
whose questions use scoring version one must generate fresh questions under
the current version-two fluency contract, rather than copying the frozen plan.

Legacy-repeat red run 34757740286 failed because repeat retained scoring
version one. Re-plan the completed focus through the current curriculum and
then retain only the repeat-facing reason, so template and scoring contracts
advance while the learner receives a fresh bounded session.

Legacy-repeat green run 34759457564 passed the full suite. Begin the locked
feedback cycle: after answer timing finishes, persist an explicit pending
surprise state. Restarting at that boundary must preserve the original answer,
confidence, verdict and response time while rejecting edits and hints until
the immutable attempt is committed.

Locked-feedback red run 34759617458 failed because no durable pending-feedback
state existed. Add backward-compatible version-six snapshots, persist the lock
only after a valid offered answer is marked, freeze timing across restart, and
reject answer, confidence and hint mutations until surprise is recorded and
the immutable attempt commits.

The first locked-feedback green run, 34761436954, showed that the existing
public timing seam is also used without confidence, where no feedback dialog
or durable lock is needed. Preserve its transient timing freeze while only
persisting `awaitingSurprise` for opted-in confidence feedback.
Locked-feedback corrected green run 34761616626 passed formatting, static
analysis, content validation, 277 native tests, seven Chrome tests, coverage
enforcement and secret scanning.

Begin the feedback-authorization cycle: the UI must not show verdict feedback
when saving the pending lock fails. Failed persistence must return false and
leave feedback unauthorized.

Feedback-authorization red run 34761795332 failed at the intended return-value
boundary. Make timing finalization explicitly report success only after the
durable pending state saves, and have the UI return without revealing or
submitting whenever authorization fails.

Feedback-authorization green run 34766455099 passed the full suite. Begin the
review-order cycle with two imported skills sharing the same due status and
deadline; their selected persisted plan must use a stable skill-ID tie-break
rather than runtime-dependent unstable-sort ordering.

Review-order red run 34766632918 failed by selecting number.estimation ahead
of the lexically earlier number.decimals at an identical deadline. After due
priority and timestamp, compare the immutable skill ID so native and web build
the same review plan from the same portable history.

Review-order green run 34767777271 passed the full suite. Add direct SQLite
characterization for the already-declared schema-v7 CHECK constraints: raw
out-of-range confidence and surprise strings must both fail at the portable
storage boundary, independently of enum-typed application callers.

SQLite boundary run 34767953183 passed the full suite: both raw invalid values
were rejected, with 279 native tests, seven Chrome tests, formatting, static
analysis, content validation, coverage enforcement and secret scanning green.
The replacement history now contains focused red/green evidence for every
review correction while preserving the verified product behavior.

PR20 supersedes PR19 because the first PR's early review fixes were batched in
a way that did not provide the required focused red/green history. PR20 began
from the implementation-complete pre-review head and reconstructed every fix as
an independent cycle. Final pre-review run 34771205534 passed before requesting
an independent review of commit 55085c6f7c.

That review identified four blockers. Two concerned this record: it still used
the PR19 path and omitted run 34771205534. Two were behavioral: imported version
six feedback locks accepted invalid or assisted states, and the feedback dialog
could derive its verdict from a stale draft while a later edit waited behind a
queued save.

Feedback-lock red run 34777907265 failed on corrupt restored locks. The initial
green implementation passed all tests in run 34778237779 but failed formatting.
Runs 34781889922 and 34783889288 documented two formatter corrections before
run 34784080373 passed the complete suite. Restored locks now require a valid,
offered draft on an independently answerable step with no assistance.

The first stale-verdict characterization in run 34787855011 passed because it
delayed the final save after the controller had already accepted the draft. The
corrected test queued the final edit behind an earlier blocked save; red run
34790047762 then failed because the dialog did not show the verdict belonging
to the durably locked answer. The isolated fix derives feedback only after the
controller finishes and persists the lock. Green run 34790517522 passed the
full suite. The provenance record was then moved to the required PR20 path and
updated through the latest review response, diagnosis, corrections and builds.
