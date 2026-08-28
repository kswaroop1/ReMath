# PR 5 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Feature selection

### User

> What next

### Assistant

> The next vertical slice should be diagnostic onboarding and initial placement,
> using the existing arithmetic generators, answer contracts, local progress,
> and resumable session foundation. Proposed scope: LX-001, the CG-003
> multi-track placement foundation, and CG-004 separation of fluency and
> understanding objectives, initially for arithmetic.

### User

> Please implement pr5 fully

### Assistant

> PR #5 will be implemented as a complete vertical slice: arithmetic diagnostic
> policy, resumable diagnostic flow, persisted evidence, onboarding/results UI,
> tracker/architecture updates, and complete provenance. Each new behaviour will
> follow strict business-focused red-green-refactor commits and the PR will
> remain draft until full scope and coverage are verified.

## Acceptance criteria

- A new learner can start an arithmetic diagnostic without an account or network.
- The diagnostic samples addition, subtraction, and multiplication independently.
- Placement distinguishes rebuild fundamentals, practise speed, and ready to
  progress using accuracy and response-time evidence.
- One weak operation does not lower an unrelated operation's placement.
- The diagnostic can be interrupted and resumed without losing answered evidence
  or the current question.
- Completion persists immutable diagnostic attempts and presents an explainable
  per-operation recommendation.
- The existing drill remains available and unchanged.
- The complete slice works offline and maintains meaningful near-100% production
  coverage.

## TDD implementation record

### Placement policy — red

The business tests first required independent addition, subtraction, and
multiplication recommendations; insufficient evidence; accuracy remediation;
speed practice; progression; and isolation from unrelated skills. Commit
`65f6165` contained the test-facing contract without the behaviour. CI run
`33184924312` failed during analysis because the diagnostic policy did not yet
exist, which was the intended missing seam.

### Placement policy — green and refactor

Commit `face7e9` added the pure-Dart placement policy. It derives accuracy and
fluent share from immutable attempts, groups evidence by operation, and returns
an objective and human-readable reason. Subsequent characterization and repair
commits ensured an unrelated skill is ignored and one operation never changes
another operation's result.

### Resumable controller — red

Commit `856f1cf` specified a nine-question diagnostic with three consecutive
samples per arithmetic operation, exact question/draft restoration, completed
session cleanup, and three independent results. CI run `33185112005` failed for
the missing diagnostic controller API, as intended.

### Resumable controller — green

Commit `1bb654b` implemented diagnostic sessions using the existing persisted
`LearningSession` and immutable `AttemptEvent` contracts. The `diagnostic-`
session namespace identifies the flow without a database migration. Placement
is rebuilt from the latest diagnostic event set, while ordinary drills retain
their existing scheduling behaviour.

### Learner journey — red and green

Commit `8b46854` specified the widget journey from “Find my starting point”
through nine locally marked answers to independent, explained results. Commit
`dbce319` added the presentation. CI then exposed two legitimate defects rather
than weakened tests: a recommendation did not match its promised learner-facing
wording, and the results overflowed on a constrained phone viewport. Commits
`3dc54df` and `0810c2f` corrected the explanation and made the overview
scrollable.

### Build diagnoses and corrections

Static analysis found a name collision with Flutter's `DiagnosticLevel`; it was
renamed to the domain-specific `DiagnosticPlacementLevel`. Analysis also caught
an incorrect assumption about the return type of `fromSkillId`; grouping was
fixed to use the returned `ArithmeticOperation`. Temporary formatting and
coverage diagnostics were used in CI while the hosted Flutter toolchain was the
only available executor. The malformed diagnostic YAML/import iterations were
corrected, and the normal non-mutating formatting gate was restored.

Green CI run `33186405183` completed 93 tests at 99.46% production line
coverage. Characterizing unrelated evidence raised the suite to 94 tests in
green run `33186820450`. Diagnostic run `33186947308` identified the remaining
four uncovered lines: the unexercised result labels and scanning past a newer
ordinary attempt to recover the latest diagnostic.

### Final coverage characterization

A final business-focused widget test preloads independent evidence that yields
“More evidence needed”, “Practise speed”, and “Ready to progress” together. It
also records a later ordinary attempt, proving that the diagnostic result is
still restored. This covers the missed branches through observable learner
behaviour. The temporary coverage-report step was then removed from CI; the
standard formatter, fatal static analysis, complete test/coverage run, content
validation, 90% emergency floor, and secret scan remain the permanent gates.

## Scope outcome

PR #5 implements LX-001 for foundation arithmetic and the CG-003/CG-004
foundations. It does not claim algebra, calculus, probability, cross-subject
placement, derivation assessment, or technique-selection assessment; those
remain explicit backlog work.
