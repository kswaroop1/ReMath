# Engineering baseline slice

PR21 pauses new mathematics content to establish a reproducible application
baseline. It completes EN-011 and EN-012 and delivers explicitly bounded
foundations for EN-019 and EN-020. It does not imply production signing, a full
device farm, cloud sync, or completion of every performance budget.

## Learner and owner outcomes

- A checkout contains reviewed Android, iOS, macOS, Windows, Linux, and web
  projects; builds no longer depend on silently generating platform runners.
- Dependency resolution starts from a committed application lock file, and CI
  fails if dependency installation changes it.
- CI launches the real application through at least one end-to-end critical
  journey using production composition rather than reconstructing domain rules
  in a test-only harness.
- Repeatable measurements protect an initial set of named startup, content-load,
  persistence, and question-transition budgets. Each budget states its runtime,
  fixture, sampling policy, threshold, and reason.

## EN-011 — committed platform runners

- Generate runners from the same Flutter stable toolchain used by CI.
- Commit only reviewed platform source and configuration; exclude ephemeral,
  generated credentials, signing material, build output, and IDE state.
- Preserve the existing application identifier and display name unless a
  documented platform constraint requires a change.
- Remove release-time `flutter create` steps after every release target builds
  from the committed projects.
- CI verifies that all required runner entry files remain present.

## EN-012 — reproducible dependency lock

- Commit `pubspec.lock` as application source.
- CI installs dependencies and rejects any resulting lock-file difference.
- Dependency or toolchain updates change the lock file visibly in their own
  reviewed pull request.

## EN-019 — critical-journey foundation

- Exercise application startup, foundation-pack loading, session start, one
  answer, durable progress, and restoration through production composition.
- Keep deterministic clocks, seeds, and temporary storage while retaining the
  real boundary wiring under test.
- Run the journey on a CI-supported target. Representative Android, Apple,
  Windows, and Linux installable-app coverage remains future EN-019 work.

## EN-020 — performance-budget foundation

- Establish stable measurement harnesses before enforcing thresholds.
- Avoid single-sample wall-clock assertions; use warm-up, multiple samples, and
  a documented statistic with enough headroom for shared CI runners.
- Report individual budget failures with measured and allowed values.
- Initial budgets cover only operations measured by this slice. Downloads,
  large future packs, lower-end physical devices, and sustained memory remain
  future EN-020 work.

## Failure and compatibility boundaries

- A missing runner or changed lock file fails CI before packaging.
- Existing local databases, immutable attempt identities, and session snapshots
  are unchanged.
- All learning remains offline and no telemetry, account, OAuth, signing key, or
  paid service is introduced.
- No release, tag, or `VERSION` change is part of PR21.
