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

Independent Codex review of 7ea489a380 reported six blockers. Five affect
behavior: chained continue-topic reset the serial while retaining its session
ID; surprise-dialog time was charged to answer fluency; imported v5 snapshots
could exceed advertised budget/chain bounds; diagnostic repeat changed
assessment semantics; and the review route ignored approaching reviews. Add
focused regression tests for each before fixing them. The sixth finding is
provenance chronology and will be corrected through the eventual final run.

Red CI run 34703257077 failed at the intended new boundaries: the timing-freeze
API was absent, chain serial reset to zero, oversized snapshots decoded, a
diagnostic accepted repeat, and the review route selected ordinary teaching
instead of approaching arithmetic review.

Review-regression tests were published before production fixes. Preserve the
serial within a continued chain; freeze and persist answer timing before showing
surprise then resume after submission; enforce session maximums on encode and
decode; leave completed diagnostics unchanged for non-stop routes; and add a
planner path that selects overdue reviews before reviews approaching within 24
hours.

Review-fix green run 34703385019 passed formatting, static analysis, content
validation, all browser and native behavior tests, coverage enforcement and the
secret scan. Update provenance through the review, its red regression run and
this green result before requesting re-review. The fixes preserve immutable
event IDs, honest response timing, bounded imported state, diagnostic semantics
and review-queue intent.

Final provenance verification run 34703580610 passed at corrected head
ccd3256b41: 273 native tests, seven Chrome tests, formatting, analysis, content
validation, coverage enforcement and secret scan. This final records-only
update adds that run and closes the chronology; it changes no product behavior.

Re-review reported five further behavior findings and one process finding. Begin
separate focused cycles with lifecycle-safe surprise timing: extend the existing
timing regression through pause/resume before the learner records surprise.
Current resume behavior restarts the answer clock, so this test precedes its
production fix. Subsequent findings will receive separate cycles.

Lifecycle timing red run 34708288334 failed because pause/resume restarted
charging after finishAnswerTiming. Keep a controller-level answer-finished
latch through lifecycle transitions and clear it only when submission either
commits or returns control after invalid input.

Lifecycle timing green run 34710063577 passed the full CI suite. Begin the next
focused cycle: an unsupported future application scoring contract carrying
confidence and surprise must remain history-only and contribute zero
calibration evidence. The controller currently forwards it to the summary.

Supported-calibration red run 34710344805 failed at that intended boundary:
the unsupported application attempt was counted as rated calibration evidence.
Filter learner calibration through the same versioned scoring-support predicate
used by mastery and planning, while retaining unsupported events in history.
The first green run, 34710588693, exposed a missing explicit scoring import at
static analysis; add that compile-time dependency before rerunning verification.

Supported-calibration green run 34710849148 passed the full suite after the
explicit import. Begin the assisted-evidence cycle at both persistence seams:
hint and correction events carrying confidence or surprise must be rejected
before they can enter either in-memory or SQLite history, including atomic
study commits.

Assisted-calibration red run 34713664256 failed because both repositories
accepted the invalid events. Validate the event at every persistence entry
point, before duplicate handling or a SQLite transaction, so hints and
corrections can never persist confidence or surprise evidence.

Assisted-calibration green run 34713894341 passed the full suite. Begin the
legacy-repeat cycle: completing and repeating an imported application plan
whose questions use scoring version one must generate fresh questions under
the current version-two fluency contract, rather than copying the frozen plan.

Legacy-repeat red run 34717410442 failed because repeat retained scoring
version one. Re-plan the completed focus through the current curriculum and
then retain only the repeat-facing reason, so template and scoring contracts
advance while the learner receives a fresh bounded session.

Legacy-repeat green run 34717594159 passed the full suite. Begin the locked
feedback cycle: after answer timing finishes, persist an explicit pending
surprise state. Restarting at that boundary must preserve the original answer,
confidence, verdict and response time while rejecting edits and hints until
the immutable attempt is committed.

Locked-feedback red run 34719837568 failed because no durable pending-feedback
state existed. Add backward-compatible version-six snapshots, persist the lock
only after a valid offered answer is marked, freeze timing across restart, and
reject answer, confidence and hint mutations until surprise is recorded and
the immutable attempt commits.

The first locked-feedback green run, 34720041703, showed that the existing
public timing seam is also used without confidence, where no feedback dialog
or durable lock is needed. Preserve its transient timing freeze while only
persisting `awaitingSurprise` for opted-in confidence feedback.

Locked-feedback corrected green run 34723385426 passed formatting, static
analysis, content validation, 277 native tests, seven Chrome tests, coverage
enforcement and secret scanning. All five behavioral findings from re-review
now have focused regression evidence and passing fixes; publish this final
chronological record before requesting another independent review.

Independent review of verified head 7e1e923f94 found that the UI could still
show verdict feedback when saving the pending lock failed, because the
controller swallowed the error behind a void result. Begin a focused cycle in
which failed persistence must return false and leave feedback unauthorized.

Feedback-authorization red run 34726464746 failed at the intended return-value
boundary. Make timing finalization explicitly report success only after the
durable pending state saves, and have the UI return without revealing or
submitting whenever authorization fails.

Feedback-authorization green run 34726644805 passed the full suite. Begin the
review-order cycle with two imported skills sharing the same due status and
deadline; their selected persisted plan must use a stable skill-ID tie-break
rather than runtime-dependent unstable-sort ordering.

Review-order red run 34730893406 failed by selecting number.estimation ahead
of the lexically earlier number.decimals at an identical deadline. After due
priority and timestamp, compare the immutable skill ID so native and web build
the same review plan from the same portable history.

Review-order green run 34731080788 passed the full suite. Add direct SQLite
characterization for the already-declared schema-v7 CHECK constraints: raw
out-of-range confidence and surprise strings must both fail at the portable
storage boundary, independently of enum-typed application callers.
