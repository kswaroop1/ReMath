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
