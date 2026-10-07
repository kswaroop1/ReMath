# Testing strategy

## Test-driven development

Every new or changed business behaviour follows a strict, observable
red–green–refactor cycle:

1. Select the feature IDs and express acceptance criteria in learner, content
   author, or product language.
2. Add one behaviour-focused test and run it to prove **red** for the expected
   reason.
3. Introduce only the interface or data-model shape needed to state that
   contract, then implement the minimum code needed for **green**.
4. Refactor only with the whole relevant suite green.
5. Repeat for the next business behaviour.

A red result is evidence, not ceremony. Record the command and relevant failure
in the pull request. A test compilation failure may briefly establish red when a
new public seam is unavoidable, but a compiling behavioural failure is preferred.
Bug fixes must reproduce the defect first. Characterization tests for existing
behaviour need not be artificially red, but must precede any refactoring they
enable.

Tests should describe observable rules—for example, “an incorrect skill is due
immediately”—rather than private methods or implementation choreography. A test
may assert a technical detail when it is itself a business or safety invariant,
such as deterministic question identity, immutable attempt events, transactional
migration, offline operation, or idempotent replay.

## Test pyramid

1. **Pure Dart unit tests:** generators, marking, mastery, scheduling, merge and
   migration rules. These comprise most tests.
2. **Repository/adapter tests:** persistence round trips, idempotent event sync,
   corrupted downloads, pack validation, and upgrade paths.
3. **Widget tests:** complete learner interactions, accessibility, responsive
   layout, interruption and resume.
4. **Integration tests:** a small set of critical journeys on each platform.

Prefer the lowest layer that proves the behaviour. Do not duplicate every unit
assertion through widgets. Use fixed clocks, deterministic IDs, seeded random
sources, and local fakes. Never use real cloud accounts in unit or widget tests.

## Coverage policy

The repository-wide line-coverage merge floor is **90%**. It is a minimum, not
the target. The objective is meaningful coverage as close to **100%** as
practical, with business-critical domain and data policies expected to approach
or reach 100% line and branch coverage.

Each pull request must maintain or improve coverage unless it documents why a
specific production path cannot be tested responsibly. Do not add assertions
that merely execute lines, test generated code, expose private methods, exclude
difficult files, or weaken the denominator. Coverage exclusions require explicit
review.

Line coverage alone does not prove correctness. Reviews must also inspect
branches, boundary values, mathematical equivalence, invalid inputs, random
seeds, time zones, interruption, offline behaviour, migrations, duplicate
events, and sync concurrency. Branch coverage will be added as the reporting
toolchain matures.

## Required evidence

Pull requests changing behaviour record:

- selected feature IDs and acceptance criteria;
- red test command and expected failure;
- green command and result;
- refactoring verification;
- final line coverage and material uncovered paths; and
- any justified coverage exception.

## Required local checks

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
dart run tool/check_coverage.dart 90
```
