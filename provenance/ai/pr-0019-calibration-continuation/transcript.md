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
