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
