# Testing strategy

## Test pyramid

1. **Pure Dart unit tests:** generators, marking, mastery, scheduling, merge and
   migration rules. These should comprise most tests.
2. **Repository/adapter tests:** persistence round trips, idempotent event sync,
   corrupted downloads, pack validation, and upgrade paths.
3. **Widget tests:** navigation, quiz interaction, accessibility semantics,
   responsive layouts, interruption and resume.
4. **Integration tests:** a small set of critical journeys on each platform.

## Coverage policy

CI starts with a 70% repository-wide line-coverage floor while the skeleton has
little executable code. Raise the threshold as domain code lands. New domain
policies and deterministic generators should normally exceed 90% and exercise
meaningful branches, not merely lines.

Coverage is a guardrail, not proof of correctness. Reviews must also inspect
boundary values, mathematical equivalence, invalid inputs, random seeds, time
zones, offline behaviour, and sync concurrency.

## Required local checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

Use fixed clocks and seeded random sources in tests. Never use real cloud
accounts in unit or widget tests. Provider contract tests must use recorded or
local fakes unless explicitly running a protected integration workflow.
