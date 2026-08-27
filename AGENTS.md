# ReMath agent guidance

This file is the repository-wide working contract for Codex and other coding
agents. More specific `AGENTS.md` files may refine it within subdirectories.

## Product intent

Build a serious, long-lived mathematical fluency and intuition trainer—not a
generic trivia quiz. Preserve offline operation, deterministic assessment, and
portable user data. The default session unit is approximately 15 minutes and
must be safely resumable.

## Architecture boundaries

- `lib/core`: cross-cutting infrastructure with no feature-specific UI.
- `lib/features/<feature>/domain`: pure Dart models and rules.
- `lib/features/<feature>/data`: persistence, content, and provider adapters.
- `lib/features/<feature>/presentation`: Flutter UI and state coordination.
- Domain code must not import Flutter, database packages, OAuth SDKs, or cloud
  provider packages.
- Provider-specific sync logic must implement a provider-neutral interface.
- Standard lesson/question content must not be mixed into personal progress.
- Never make network access or an AI API mandatory for answering a question.

## Data invariants

- Record attempts as immutable, uniquely identified events.
- Use UTC instants for persisted event times and retain timezone only where a
  user-facing schedule requires it.
- A generated question identity includes template ID, template version, and
  seed, so every device can reproduce it.
- Sync merges events; it must never resolve concurrency by blindly replacing a
  complete database.
- Database and content-pack migrations must be forward-tested and reversible
  where practical.

## Quality bar

For every behavioural change:

1. add or update tests at the lowest useful level;
2. run formatting, static analysis, and the complete relevant test suite;
3. test failure, interruption, offline, and duplicate-event paths where relevant;
4. update architecture/content documentation when contracts change.

Do not reduce assertions, disable lints, or weaken coverage thresholds to make a
change pass. Avoid snapshot/golden tests for logic that is clearer in unit tests.
Use widget tests for interactions and a small number of goldens for stable,
high-value visual contracts.

## Required checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

CI enforces a line-coverage floor. New domain and data code should normally have
near-complete branch coverage even when the repository-wide threshold is lower.

## Dependencies

Prefer the Dart/Flutter standard libraries. Before adding a package, document:

- why it is needed;
- supported target platforms;
- maintenance and licence status;
- data/privacy implications;
- the abstraction preventing it from leaking into domain code.

Never commit secrets, OAuth client secrets, signing keys, API keys, generated
credentials, or personal learning data.

## Content rules

- Use original explanations, diagrams, questions, and solutions unless a source
  licence explicitly permits inclusion and attribution is recorded.
- Links may point to external refreshers; do not copy video/course content.
- Every question needs a stable skill ID, difficulty metadata, answer contract,
  explanation, and misconception tags where appropriate.
- Parameterised generators must constrain inputs to avoid ambiguity, undefined
  operations, accidental duplicate answers, and numerically unstable marking.

## Commit discipline

Keep commits focused and use imperative messages. Do not modify unrelated user
work. Explain migrations and architectural decisions in the commit body or an
ADR when they are not obvious.
