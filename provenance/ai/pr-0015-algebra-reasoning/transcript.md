# Chronological implementation record

User: "Yes please, keep working, i will in parallel, as i get time, keep merging prs"
User: "Btw, Pr 14 merged"

Continue increments 2–4 as sequential/stacked PRs; merges remain the user's action.
PR14 merged as 906d3ed. Its external Codex review identified four findings:
constant-only linear input; syntactic cancellation bypassing collected form;
web/native seed arithmetic differences; prerequisites outside goal membership.
Review: https://github.com/kswaroop1/ReMath/pull/14#pullrequestreview-5145699448

Scope was saved locally before implementation as 160077b. GitHub publication was
rejected by automatic approval review because credits were exhausted.
User: "We had run out of credits, pl continue now."
Resumed publication through the same GitHub connector; opened draft PR15.
Local and remote Git-object publication preserves commit subjects/order but hashes
can differ. Local Flutter remains unavailable following the earlier runner
rejection; CI is the verification authority. Routine telemetry omitted.

## Cycle 1: PR14 review regressions

Compiling regressions exercise the existing public interfaces. Add Chrome CI for
these pure domain contracts to reproduce the real web precision fault, rather
than simulating a different runtime. Preserve the native full-suite coverage gate.
No production fix is in the test-first commit.

Cycle 1 red: run 34299378856 passed analysis and reproduced all four findings in
Chrome: constant-form and cancellation inputs incorrectly passed, seed zero
produced 5x+2x instead of 2x+2x, and algebra skipped arithmetic.addition.

Use BigInt for the unchanged algebra recurrence, enforce syntactic constant form,
and retain syntactic variable-sum checks during multiplication. Planner progress
includes all bundled skills but overdue selection remains within the chosen goal.
Existing symbolic-journey tests now explicitly explore collecting terms so they
continue testing symbolic interactions; the new regression separately asserts
normal prerequisite-first planning. No behavioural assertion is removed.

Cycle 1 green: run 34299604614 passed all four regressions in Chrome and all
223 native tests, 99.96% coverage. The formerly uncovered prerequisite path is
now exercised; only the inherited number-generator fallback remains uncovered.

## Cycle 2: structured reasoning contracts

Add tests for ordered derivations, missing expanded expressions, identifying the
first invalid step plus category, and penalty-adjusted multiple-select credit.
Require duplicate/unknown/incomplete selection rejection, deterministic replay,
original worked hints and bounded identities. ReasoningCurriculum is the necessary
new public seam. No reasoning production code is in this test-first commit.

Cycle 2 red: run 34299839452 failed analysis for the missing ReasoningCurriculum
public seam. Implement four original deterministic question kinds. Typed answers
serialize stable option IDs as JSON; missing expressions reuse exact symbolic
marking. Multiple-select credit is derived from immutable answer plus versioned
question identity, not a mutable score stored separately. Human worked answers
remain distinct from the serialized draft.

Run 34300054221 reported three multiline-if brace lints. Correct the braces
without changing assessment behaviour or assertions.
