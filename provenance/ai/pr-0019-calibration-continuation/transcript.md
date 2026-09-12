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
