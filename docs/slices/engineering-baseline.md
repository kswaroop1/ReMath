# Engineering baseline slice

PR21 pauses new mathematics content to establish a reproducible application
baseline. It completes EN-012 and delivers explicitly bounded
foundations for EN-011, EN-019 and EN-020. It does not imply production signing, a full
device farm, cloud sync, or completion of every performance budget.

## Learner and owner outcomes

- A checkout contains reviewed Android, iOS, macOS, Windows, Linux, and web
  projects; ordinary CI checks their presence. Release builds still regenerate
  runners, so EN-011 is incomplete.
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

## Review correction acceptance (19 September 2026)

- EN-020 rejects negative warm-up counts and reports fractional milliseconds
  accurately when a near-boundary measurement fails. Each gets a separate
  regression-first commit.
- EN-019 characterizes existing production main/bootstrap with a temporary
  application-support directory, closes storage, reopens it, and restores the
  same correction and immutable attempt. This is characterization, not new
  learner behavior.
- EN-020 measures that same bootstrap and file-backed writes.
- EN-012 declares the Dart 3.11 minimum required by its committed resolution.
- EN-011 remains incomplete pending builds from unchanged committed runners.
- Preserve the historical provenance and append attributable available exchanges;
  explicitly disclose unavailable earlier exports rather than inventing them.

## Initial performance measurement contract

Runtime: Flutter debug widget tests on the shared Ubuntu CI runner. Fixture:
shipped foundation asset and temporary file-backed schema-v7 SQLite, with only
the OS application-support-directory lookup replaced. Two warm-ups precede five
measured samples; the median must not exceed the budget.

| Operation | Limit | Measured boundary and rationale |
| --- | --- | --- |
| Content load | 250 ms | Asset read and parse; generous headroom for the small shipped pack |
| Application startup | 2 s | Production main, asset load, directory lookup/create, SQLite open/migrate and settled first UI; includes teardown, making the bound conservative |
| Attempt persistence | 100 ms | Real file-backed SQLite attempt write; bounds interactive write latency |
| Question transition | 500 ms | File-backed controller initialization, session start, answer and teardown; conservative bound for the transition |

Startup samples reuse the directory after the first warm-up, so this is warmed
startup, not a fresh-install or cold OS-cache budget. These are broad regression
guards, not release-mode device latency claims. The integration journey separately
starts with a missing support directory.

Test dependency: path_provider_platform_interface 2.1.3 is already locked as a
transitive Flutter-maintained BSD-3-Clause package. Declaring it directly for
tests allows an OS-directory substitute across native targets without changing
production wiring. It makes no network calls and carries no user data in this
fixture; no provider package is introduced into domain code.
