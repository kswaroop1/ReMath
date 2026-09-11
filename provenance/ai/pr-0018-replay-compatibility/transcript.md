# Seeded replay compatibility

User authorized continued work while independently merging PRs, then reported
PR15 and PR16 merged. Reviewing PR15 found a P1 identity compatibility defect:
PR15 made v1 exact on web, changing prompts under pre-existing IDs. It also found
level-2 balance diagnosis routed to algebra.expand. The provenance review finding
was already corrected in the merged final commit. Select the remaining fixes in
 docs/slices/replay-compatibility.md before implementation; stack on PR17.

Cycle 1 select/red: preserve legacy browser and native fixtures under v1, put
future portable generation under v2, keep fresh plans on the current contract,
and route balance remediation to algebra.linear. The browser-origin parameter
is a necessary new public seam for explicit legacy reconstruction; tests may
initially fail compilation until it exists. Retain VM/Chrome regression checks.

Before implementation, update current-generator expectations to v2 and move the
unknown-template rejection fixture from v2 to v3. This preserves rejection of an
unsupported future contract while explicitly selecting v2 as current. Historical
v1 browser/native assertions remain in the new compatibility regression.

Cycle 1 red: run 34410270340 failed on the missing legacy-browser parameter
and current-generator IDs still using v1; 238 native tests passed. Implement
an explicit browser floating-point recurrence for legacy v1 reconstruction and
v2 for future exact portable numeric/algebra generation. Fresh plans pin current
versions; frozen v1 plans remain supported. Balance diagnosis selects the linear
prerequisite. Saved-session ambiguity is deliberately handled in the next cycle.

11 September continuation: user confirmed PR17 merged and requested “Ok do
proceed.” The previous implementation publish had been rejected by automatic
approval review because the account usage limit was reached. Published the saved
implementation after access resumed. No CI run appeared because the PR conflicted
with PR17's squash merge. Merge current main and keep both the application mixed
plan and the new version-pinning helper; no feature or assertion is removed.

Cycle 1 green: run 34652105904 passed formatting, analysis, seven Chrome
regressions and 247 native tests, with 99.90% coverage. Explicit legacy browser
and native fixtures match on both platforms, future questions use v2, and balance
remediation uses linear equations.

Cycle 2 select/red: old v1 numeric/algebra active snapshots have no reliable
origin. Require an explicit persisted choice before any answer or step advance,
keep their draft and active budget intact, and preview both possible questions.
New portable sessions require no choice. New attempts from a chosen legacy
session must carry an origin suffix; historical events are untouched. Snapshot
v3 carries the selected generator, and unknown generators must preserve data.
The required new state/controller selection interface may initially fail compile.

PR17 review follow-up: GitHub's PR commit list confirms nine separate commits,
including test-only cc518dc0a8ab33737f129a6e4680c2eeefb28b4b and
396dd1f1a536722e27bcd30db689fe9218de8c7d before their implementations.
The history finding is contradicted by that source; no history rewrite is needed.
Malformed JSON recovery and invalid application evidence still need focused
checks, and an application-specific timing policy belongs with versioned scoring
in the pending calibration increment. These are not yet claimed resolved.

Cycle 2 red: run 34652437777 failed for the absent origin-selection state/API
and snapshot schema still being v2; 246 native tests passed. Implement snapshot
v3 with an explicit nullable origin for unresolved old sessions. Block answering,
step advance and active-time consumption until a persisted choice succeeds;
preview possible questions and retain the saved draft. Qualify new legacy answer
and hint identities with origin-browser/origin-portable; old events are unchanged.
Posted PR17 commit-history evidence in comment 5641181557, without retriggering
review or claiming its remaining findings fixed.
