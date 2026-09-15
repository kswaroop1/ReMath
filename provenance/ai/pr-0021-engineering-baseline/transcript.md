# Engineering baseline

User observed that delivery had progressed through content-led vertical slices
but expressed concern about the relative lack of non-functional,
infrastructure, and technical feature progress. After reviewing the original
feature register, roadmap, architecture, tests, workflows, and implementation,
the agent confirmed that the concern was justified and recommended pausing new
mathematics content for a bounded infrastructure programme.

User confirmed that PR19 was closed and PR20 merged, then requested that the
feature register first be reconciled and committed, potentially as part of
PR21.

Reconciliation: compare every claimed infrastructure foundation with repository
evidence rather than interpreting an architectural intention as implementation.
Keep incomplete capabilities unchecked and state their delivered boundary.
Correct the stale review date, the generated-versus-committed platform-runner
boundary, existing ADR coverage, content-pack parser/validator/CI foundations,
database migrations through schema v7, local idempotency and session snapshots,
the absence of behavioural analytics, and the current CI test boundary.

The documentation-only reconciliation was committed separately and published
as the first checkpoint of draft PR21. Its planned bounded implementation scope
is EN-011, EN-012, an EN-019 critical-journey integration foundation, and EN-020
performance-budget foundations. No release, signing credential, cloud sync,
content expansion, or VERSION change is included.

After the user asked whether work was continuing, clarify that the prior
continuation automation ended with PR20 and that no background work occurred
between messages. Resume PR21 and verify reconciliation CI run 34893291023 is
green. Select the engineering baseline before behavioral work: record exact
learner/owner outcomes, platform-runner and dependency-lock invariants, the
bounded integration and performance foundations, failure behavior, and explicit
out-of-scope boundaries in `docs/slices/engineering-baseline.md` and the roadmap.

Cycle 1 select/red: EN-011 and EN-012 require reviewed platform projects and an
application dependency lock to exist at checkout, before dependency installation
or packaging can silently generate them. Add a CI structure check naming the
minimum Android, iOS, Linux, macOS, web, and Windows entry files plus
`pubspec.lock`. The current repository should fail this technical invariant at
the intended missing-file boundary; no runner or lock production files are added
in the red commit.

Cycle 1 red: CI run 34971033181 failed at the intended committed-structure
check before dependency installation. The missing boundary includes
`pubspec.lock` and the required Android, iOS, Linux, macOS, web, and Windows
runner entry files. Add a temporary pull-request-only CI job that uses the same
Flutter stable action as repository CI to generate and archive those sources.
The quality job remains red until the generated sources themselves are reviewed
and committed; this job is generation transport, not the EN-011/EN-012 fix.

Generation run 34994064139 produced the expected projects and lock file, but the
artifact action's default omitted the platform `.gitignore` files. Preserve
those generated exclusions in the review input by enabling hidden-file upload
for the explicitly bounded platform directories; root metadata and repository
state remain outside the artifact paths.

Cycle 1 green implementation: generation run 34994408835 successfully archived
the stable-toolchain platform sources including their exclusions. Review the
archive and omit ignored machine-local or ephemeral output: Android local
properties/IDE files and wrapper binaries, Apple generated configuration and
ephemeral packages, and Flutter ephemeral directories. Commit the remaining
reviewed Android, iOS, Linux, macOS, web, and Windows projects plus
`pubspec.lock`. Remove the temporary archive job so ordinary CI consumes the
committed projects. After dependency installation, CI must also reject any
lock-file diff.

The repository write guard rejected replacing the existing release workflow
because that file contains publication permissions. Do not retry or circumvent
the denial. Leave the release workflow unchanged in this cycle; removing its
now-redundant `flutter create` steps is deferred until the owner explicitly
authorizes that workflow edit.
