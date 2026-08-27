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

## Mandatory test-driven development

All new or changed business behaviour uses strict red–green–refactor:

1. **Select.** Name the feature IDs and write learner/business acceptance
   criteria before implementation.
2. **Red.** Add the smallest behaviour-focused test first. Run it and preserve
   evidence that it fails for the intended missing behaviour. A compile failure
   is acceptable only while introducing a necessary public seam; prefer a
   compiling test with the minimum interface or data-model shape needed to state
   the contract.
3. **Green.** Write only enough production code to satisfy the failing business
   example and the existing suite.
4. **Refactor.** Improve names, duplication, design, interfaces, and data models
   only while the entire suite remains green.
5. **Repeat.** Use another red–green–refactor cycle for the next behaviour; do
   not batch untested production behaviour into a large implementation commit.

Tests should read as rules a learner, content author, or product owner would
recognise. Assert observable outcomes and durable contracts rather than private
methods, widget structure, SQL statements, call counts, or implementation order
unless that technical property is itself a required invariant. Use test doubles
at infrastructure boundaries, not to restate the implementation.

Bug fixes begin with a reproducing failing test. Existing-behaviour coverage work
uses characterization tests and must not manufacture a failure by breaking
production code. Refactoring-only changes require the relevant suite green
before and after.

A pull request must record the red command/failure, green command/result, and
refactoring verification. Never change a test merely because correct production
code cannot satisfy it; resolve whether the requirement, test, or implementation
is wrong and document the decision.

## Required checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

CI enforces a 90% repository-wide line-coverage floor. The engineering objective
is meaningful coverage as close to 100% as practical, not merely passing 90%.
Business-critical domain and data policies should normally reach 100% line and
branch coverage. Any intentionally uncovered production line requires an
explicit PR justification; exclusions and coverage-only tests that assert no
business or safety contract are prohibited.

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

## Releases

- Do not edit `VERSION` unless the user explicitly chooses a new major/minor.
- The commit changing `VERSION` is patch zero for that line.
- Never create, move, or replace a release tag outside the manual release workflow.
- Release only from the default branch after CI succeeds.
- Treat published tags and release assets as immutable.

## Commit discipline

Keep commits focused and use imperative messages. Do not modify unrelated user
work. Explain migrations and architectural decisions in the commit body or an
ADR when they are not obvious.
