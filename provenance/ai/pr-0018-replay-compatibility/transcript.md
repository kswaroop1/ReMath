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
