# Chronological implementation record

User: "Merged. Please plan another vertical slice to implement another large coverage of core features."

Assistant proposed four sequential, independently usable PRs: solve algebra;
explain algebra; apply algebra; calibrate and continue. The first increment covers
bounded symbolic marking, algebra goal/diagnostic, teaching, correction/retest,
resumable symbolic drafts and the start of scoring versioning.

User: "Ok"

Start from merged PR13 commit 92e726ed. Record acceptance before implementation in
docs/slices/algebra-solving.md and open draft PR14. No release or merge requested.
Local working copy is clean. Publish local commit subjects in the same sequence
through GitHub Git objects; local and remote commit hashes can differ.

## Cycle 1: bounded symbolic marking

Add compiling tests with a minimal SymbolicAnswer public seam whose mark method
throws UnimplementedError. Contracts cover exact rational polynomial equivalence,
requested collected/expanded form, syntax/domain rejection and resource limits.
Division by any syntactically variable expression is unsupported even if it could
simplify to a constant; this avoids silently losing domain restrictions.
No random substitution or AI verdict is used.

Use CI for Flutter verification, continuing the earlier runner decision: local
Flutter execution was abandoned after an automatic-review rejection of its
metadata-network startup. Local Dart formatting remains available. No local test
success is claimed. Routine command telemetry is omitted.

Cycle 1 red: CI run 34228364008 passed analysis and failed the four new
SymbolicAnswer cases with UnimplementedError. Implement exact rational polynomial
normalization, bounded recursive-descent parsing and a separate collected-form
check. Syntax is never executed as code. Preserve variable-use information even
when a subexpression simplifies, so domain-changing division stays unsupported.
