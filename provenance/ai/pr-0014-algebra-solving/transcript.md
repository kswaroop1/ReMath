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

## Continuation after credit limit

User: "We had run out of credits, pl continue now."

The green implementation was saved locally as 011495f but its GitHub publication
was rejected by automatic approval review because credits were exhausted. After
the user resumed, confirmed the remote still held the test-only commit and
published the saved implementation. Run 34260436411 reported a missing braced
multiline if body; correct that lint without changing marking logic or tests.

Cycle 1 green: run 34260703215 passed all CI checks, coverage 99.87%.

## Cycle 2: reusable algebra question catalogue

Add tests for the combined catalogue, preserving both number goal memberships
and version-one number identities. Independently calculate expected answers from
225 algebra prompts across collecting terms, expansion and linear equations.
Require teaching/prerequisites, four hints, deterministic versioned identities,
no fabricated symbolic MCQs and invalid-identity rejection. StudyCurriculum is a
necessary new public seam; the test-first commit contains no catalogue behaviour.

Cycle 2 red: run 34260971722 failed analysis because the necessary
StudyCurriculum interface did not exist. Implement the combined catalogue,
original algebra templates and shared StudyQuestion interface. NumberSkill and
number-format names remain compatible; the number generator and goal sets do
not change. Algebra has no MCQ choices in this increment.

Cycle 2 green: run 34261285564 passed all checks, coverage 99.43%. The new
uncovered lines are input labels/guidance pending their real UI integration,
plus unary-plus handling and the two already documented defensive catalogue lines.

## Cycle 3: offline algebra journey and versioned evidence

Add compiling behavioural tests against the existing planner/controller/screen:
algebra goal and independent diagnostic, exact symbolic draft/correction restore,
full learn-practise-reflect completion, sixty-second algebra fluency policy,
versioned immutable evidence/replay, unsupported-score exclusion, old snapshot
compatibility and unknown-contract preservation. Widget tests require text-keyboard
entry, saved drafts, explicit grammar feedback and focus after correction.
No production integration is included in this test-first commit.

Cycle 3 red: run 34261551596 passed analysis and failed the intended journey
contracts: algebra remained number-fluency, diagnostic had 19 rather than 10
steps, sixty-second successes did not promote, unknown scoring events counted,
and unsupported saved versions were accepted. The algebra goal widget was absent.

Integrate the shared catalogue and question interface into the existing controller
and UI. Algebra plans use symbolic entry throughout; numeric plans retain MCQs.
Snapshot version two freezes template/marking/scoring versions; version-one
numeric snapshots receive explicit defaults. Reject unsupported contracts and
algebra snapshots claiming legacy format, retaining their stored bytes.
Version-one algebra evidence permits sixty-second independent fluency; unknown
versions remain visible in history without mastery credit. No SQL schema change
is required because the existing atomic study snapshot is versioned JSON.

Run 34261955387 reported directives_ordering in the controller imports. Correct
only import order; no assertions or production behaviour change.

Cycle 3 green: run 34262123821 passed the full suite and all checks, 99.88%
coverage. Shared numeric regressions and all new offline algebra journeys pass.

## Cycle 4: discoverable shared navigation and boundary characterization

The home entry still says Number learning journey despite offering algebra.
Require the generic Learning journey label and verify both goals are reachable
from it. Update the existing tests' exact navigation text while retaining their
behavioural assertions; the production label is unchanged in this red commit.
Also characterize already implemented signed rationals/zero powers, explicit
unknown question versions, linear input guidance and unsupported-history display.
These latter cases have green-before evidence and do not add new behaviour.

Cycle 4 red: run 34262445769 passed analysis and failed navigation because
Learning journey was absent. Rename the single existing home entry; both goals
continue to use the same route. The characterization boundaries require no
production change.


## Final implementation verification

Run [34262695601](https://github.com/kswaroop1/ReMath/actions/runs/34262695601)
passed the complete test suite and CI: formatting, fatal-warning/info analysis,
content validation, coverage enforcement and secret scan. Coverage is 99.92%,
compared with PR13's 99.91%. Every new symbolic marking line is covered.
Only the two inherited defensive lines remain uncovered:

- `number_curriculum.dart:329`: unknown-generator fallback after a validated
  lookup in the fixed, fully implemented number catalogue.
- `study_plan.dart:230`: prerequisite-redirection explanation. Current goals
  already list prerequisites before dependent skills; first-unmastered selection
  therefore selects unmet prerequisites before reaching that fallback.

No exclusions, assertions or coverage gates were weakened. The final navigation
label tests and all characterization cases pass. No local Flutter execution,
real-device verification, release or merge is claimed. The full commands are:
`dart format --output=none --set-exit-if-changed lib test tool`,
`flutter analyze --fatal-infos --fatal-warnings`, content validation,
`flutter test --coverage`, and `dart run tool/check_coverage.dart 90`.

Update README, feature statuses, the four-increment roadmap and ADR 0004 to reflect
this first bounded increment. QA-003 and MP-020 remain foundations; MA-004/005
remain partial. Structured reasoning, challenges, confidence and session controls
are subsequent increments, not completed by PR14. Sixty-second algebra fluency
is an explicit provisional v1 rule, not an empirical calibration claim.

After the documentation head passes CI, mark PR14 ready and send the previously
agreed single Codex review request. No external review result is claimed here.
