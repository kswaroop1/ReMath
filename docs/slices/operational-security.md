# Operational-security slice

Follows merged PR #24 at `6e187b0b`. This is the final accepted infrastructure
slice, not permission to add cloud sync, AI services, or new curriculum.

## Feature scope

- **SP-006 / CP-005:** explicit offline publisher public-key trust, Ed25519
  verification at the existing archive-verifier boundary, durable onboarding,
  rotation and revocation, and fail-closed production composition.
- **SP-011:** a repository threat model covering malicious packs, trust bootstrap,
  device compromise, credential theft, backup tampering, replay and supply chain.
- **SP-012:** document reuse of the existing cryptography dependency and review
  security-sensitive boundaries without introducing new packages.

## Acceptance contract

1. Unknown publishers and keys are untrusted by default. Only an explicit local
   operator decision admits a public key; pack metadata cannot grant itself trust.
2. Trusted key identity is immutable and binds publisher identity to Ed25519 public
   bytes. Duplicate identical onboarding is idempotent; conflicting identity reuse
   is rejected. Public input is bounded and malformed keys fail closed.
3. Rotation explicitly admits a new key for the same publisher without silently
   revoking the old one. Revocation is durable, irreversible for that key identity,
   and blocks subsequent verification, including after restart.
4. Signature verification authenticates the existing canonical release payload,
   including its archive digest and install metadata. Wrong keys, tampering,
   malformed signatures and revoked keys never authorize installation.
5. SQLite trust operations are atomic and survive interruption and duplicate
   requests. Production composition reads that trust store, never an accept-all
   verifier. Empty trust retains bundled offline learning as the safe fallback.
6. Tests cover domain decisions, durable restart, cryptographic negative cases,
   and the production-composed installation path. Every behaviour has separate
   test-first red and green commits; CI supplies unavailable Flutter evidence.
7. Threat-model documentation states residual risks honestly: a compromised
   device can change local trust; offline revocation requires explicit local
   distribution; installed curriculum is not silently deleted by key revocation.
8. Full CI and explicit independent review must pass before marking review-ready.
   Feature checkboxes remain open until their acceptance evidence exists.

## Exclusions

No private signing keys or credentials, signing service, release, `VERSION` change,
platform-runner regeneration, cloud/OAuth, AI onboarding, transparency service,
automatic trust-root download, or remote repository-protection changes.

## Implementation checkpoint — 26 October 2026

Full CI run [40264531840](https://github.com/kswaroop1/ReMath/actions/runs/40264531840)
passes on `3a59875e`. Completed foundations, not complete feature acceptance:

- Explicit in-memory and SQLite public-key enrollment; bounded identities and
  32-byte key shape validation; conflicting identities cannot replace trust.
- Idempotent duplicate enrollment across connections.
- Durable irreversible revocation and trusted-public-key lookup.
- Existing-behaviour coverage for explicit rotation, cross-connection conflict
  preservation, and transaction rollback verified after closing/reopening.

Chronological red/green and characterization evidence is in
`provenance/ai/pr-0028-operational-security/transcript.md`.
Rollback coverage is not a process-kill or disk-failure simulation; sequential
cross-connection examples are not simultaneous concurrency evidence.

Remaining acceptance work:

- Complete full signed-release installation coverage using production-composed
  durable trust (factory-level composition is verified).
- Explicit operator onboarding/rotation path and concurrency/failure hardening.
- Threat model, dependency security assessment, feature-register reconciliation,
  coverage review and explicit independent review.

PR28 remains draft. SP-006 and CP-005 remain incomplete. No signing credentials,
release, VERSION change or merge is included.

## SP-011 threat model — implementation review draft

Assets: personal progress/attempt events, recovery archives, installed curriculum,
operator-approved publisher identities, and the integrity of installation
decisions. External content and backup input are untrusted. The local operator
and uncompromised application/storage are the trust root; pack metadata is not.

| Threat / boundary | Required control and current limitation |
| --- | --- |
| Malicious content pack entering staging | Enforce archive bounds, digest and manifest validation before activation. A matching digest alone is not publisher authentication. The native lifecycle now composes Ed25519 with durable trust; unknown keys remain rejected. Full signed-release installation coverage is still outstanding. |
| Publisher impersonation / trust bootstrap | Require explicit operator approval of independently obtained public bytes and publisher/key identity. Never enroll from pack claims. Unique key-only resolution rejects multiple publisher claims, even after revocation. The operator onboarding path is unfinished. |
| Tampered release metadata / archive | Verify Ed25519 over the canonical release payload, which includes archive digest and install metadata. Ed25519 primitive and native-factory tests pass, including tampering, wrong keys, revocation and ambiguity; full release installation evidence remains pending. |
| Replay / downgrade | Preserve lifecycle version and compatibility checks. A valid signature alone does not establish freshness. Offline devices cannot discover newer releases or revocations automatically. |
| Key compromise / rotation | Explicitly admit a new identity; distribute revocation locally and persist irreversible tombstones. Until revocation reaches a device, a compromised trusted key remains a risk. Existing installed curriculum is not silently deleted. |
| Backup tampering / hostile recovery input | Treat imported data as untrusted, validate format and integrity, and preserve atomic recovery boundaries. An unkeyed checksum detects corruption, not malicious authorship. Do not claim encryption/authentication beyond the implemented backup contract. |
| Device compromise / local database modification | Defensive stored-type/length checks deny malformed keys. An attacker controlling the device can substitute valid keys, alter the binary or read local data; this slice cannot protect against that attacker. |
| Credential theft | This slice handles public keys only, introduces no signing credentials and does not provide a signing service. Existing user/provider secrets must not enter packs, backups, logs or provenance. |
| Supply-chain compromise | Retain dependency lock, secret scanning, pinned workflow actions and review of dependency changes. Passing CI does not prove a dependency or build host is uncompromised. No new package is introduced by this slice. |
| Interrupted / competing local operations | SQLite transaction rollback, restart and duplicate/conflict examples have coverage. Simultaneous races, process termination and disk failure are not established by those examples and require separate evidence. |

Residual-risk acceptance must remain explicit in review. The complete slice is
not review-ready until cryptographic negative cases, production composition,
operator controls and independent review satisfy the acceptance contract.

## Verified native verification checkpoint — 27 October 2026

Full CI [40458220054](https://github.com/kswaroop1/ReMath/actions/runs/40458220054)
passes on `35343e33`. The native lifecycle now selects Ed25519 verification
using the same SQLite database's publisher trust store. Key-only IDs resolve
only when one publisher/key pair claims them; revoked claims still contribute
to ambiguity. Unknown, revoked, malformed and ambiguous keys/signatures are
denied in the covered examples.

Public RFC vectors establish primitive correctness and factory wiring, not a
full canonical-release installation journey. Explicit operator onboarding,
remaining race/interruption evidence, dependency assessment, coverage review
and independent review remain open. Feature completion is not claimed.

## Verified defensive recovery checkpoint — 27 October 2026

Full CI [40572197316](https://github.com/kswaroop1/ReMath/actions/runs/40572197316)
passes on `c214b268`. In addition to native trust/revocation restart verification,
the SQLite installer rejects untrusted releases without activation and preserves
bundled fallback. Malformed stored publisher identities resolve as untrusted
without a cast exception. Closing an unfinished transaction preserves prior
committed trust and discards its uncommitted revocation/new enrollment on reopen.

The close/reopen example is not process-kill, power-loss or disk-failure evidence.
It does not establish simultaneous concurrency safety. Successful signed canonical
release installation, explicit operator controls, dependency assessment, coverage
reconciliation and independent review remain required. SP-006/CP-005 stay open.

## Next bounded operator-control increment

Implement a local application service over the existing SQLite trust store;
content installation must never call its admission path. Admission requires an
explicit confirmation flag plus publisher ID, key ID and independently obtained
32-byte public key. Without confirmation, refuse without changing durable trust.
A confirmed identical admission is idempotent; conflicting reuse and revoked
identities remain rejected by the existing store. Rotation admits a new key ID
without silently revoking the old one. Revocation requires explicit confirmation
and remains binding even before first enrollment and after restart.

Tests must first establish unconfirmed admission/revocation cannot mutate trust,
then confirmed admission, duplicate/conflict, rotation and durable revocation.
This application boundary is not itself a user-facing UI or command-line tool;
operator access and instructions must be composed separately before completion.
No private signing material or automatic trust download is included.

## Verified operator-service checkpoint — 28 October 2026

Full CI [40682860127](https://github.com/kswaroop1/ReMath/actions/runs/40682860127)
passes on `76c81778`. PublisherTrustOperator now refuses unconfirmed enrollment
and revocation before durable mutation. Confirmed operations delegate to SQLite
trust policy. Tests verify exact admission, duplicate/conflict preservation,
irreversible revocation, explicit rotation without silent old-key removal, and
new-key trust/old-key denial after database close/reopen.

This service is not yet exposed as an operator UI or command-line tool. Native
trust remains empty until explicitly populated; content metadata cannot admit
itself. User-facing composition/instructions, successful signed canonical-release
installation, concurrency/failure hardening, dependency/coverage assessment and
independent review remain acceptance work. SP-006/CP-005 remain incomplete.

## Verified command-adapter checkpoint — 29 October 2026

Full CI [40900873476](https://github.com/kswaroop1/ReMath/actions/runs/40900873476)
passes on `0ec7a7ca`. The local adapter accepts only exact confirmed enrollment
and revocation grammars. Missing/wrong confirmation, unknown commands, malformed
hex and excess arguments return nonzero without admission or unintended
revocation. Enrollment conflict and invalid identity return failure without
replacing trust; storage exceptions are not converted into success.

This adapter is not an executable operator tool. The next bounded boundary must
require an explicit existing SQLite path, refuse missing paths without creating
files, compose the tested operator/command service, close storage on every path,
and return truthful process status. Do not guess the platform application path
or silently create a separate trust database. Operator instructions must explain
independent public-key verification, rotation and irreversible revocation.
Successful signed installation and remaining security assessment/review stay open.

## Local operator tool — 30 October 2026

Full CI [41040075730](https://github.com/kswaroop1/ReMath/actions/runs/41040075730)
passes on `84cfbe54`, including successful Dart-process enrollment and persisted
public bytes verified after reopening.

Run from a checked-out repository with its locked dependencies installed. Close
ReMath first and identify the exact existing `remath-content.sqlite` used by
that installation. Do not use the personal-progress database or invent a new path.
Keep a recoverable copy before modifying trust. The tool does not discover paths,
create missing database files, download trust roots or handle private signing keys.

Independently verify the publisher identity, key ID and all 32 public-key bytes
through a trusted channel before admission. A key supplied inside the pack is
not evidence of its own authenticity. The hex argument is exactly 64 hex digits.

```text
dart run tool/publisher_trust.dart "<existing-content-database>" enroll <publisher-id> <key-id> <64-hex-public-key> --confirm
dart run tool/publisher_trust.dart "<existing-content-database>" revoke <publisher-id> <key-id> --confirm
```

Rotation: explicitly enroll a distinct new key ID, verify its intended use, then
explicitly revoke the old identity when appropriate. Admission does not silently
revoke earlier keys. Revocation is irreversible for that publisher/key identity,
including future re-enrollment, and does not delete already installed content.
Offline devices require their own explicit local updates. A key ID claimed by
multiple publishers cannot authorize verification, even after one claim is revoked.

Exit status: 0 means the command completed; 64 means unsupported/malformed command
or missing confirmation; 65 means enrollment identity/conflict/revocation policy
refused admission; 66 means no supplied existing file. SQLite failures during composed command/table access return 74 and still close
storage. Opening failures before that scope and other runtime failures can still
surface as uncaught process errors, never successful commands.
Do not interpret silence as success: inspect the process exit status.

Limitations: this is a developer/operator tool, not a packaged mobile UI. It opens
the selected existing SQLite database and may create trust tables there; selecting
the correct application content database is the operator's responsibility.
Process-level revocation/failure coverage and remaining signed-installation,
concurrency/security assessment, coverage reconciliation and independent review
remain acceptance work. SP-006/CP-005 are not marked complete.

## Verified operator failure checkpoint — 30 October 2026

Full CI [41092988680](https://github.com/kswaroop1/ReMath/actions/runs/41092988680)
passes on `44b2ccc9`. Process revocation persists after reopening and prevents
re-enrollment. Empty/missing/directory paths are refused without file creation.
An existing non-SQLite fixture reports failure while preserving its original
contents. These examples do not establish safety for every corrupt database,
opening failure, concurrent process, filesystem fault or privileged attacker.

The operator tool is usable at its documented developer boundary; broader
signed-installation, concurrency/failure assessment, dependency/coverage review,
feature reconciliation and independent review remain outstanding.

## Verified competing-process checkpoint — 30 October 2026

Full CI [41109286166](https://github.com/kswaroop1/ReMath/actions/runs/41109286166)
passes on `3293d021`. Two concurrently launched operator processes compete to
admit different public bytes for one publisher/key identity. The example requires
exactly one success, a conflict or SQLite-contention failure for the other, and
the successful process's exact public bytes after reopening storage.

Concurrent process launch does not force a particular SQLite instruction
interleaving or prove all race schedules safe. In particular, this is not a
revocation-versus-verification race test or process-kill/disk-failure evidence.
The signed canonical-installation journey and final security assessment/review
remain open; SP-006/CP-005 remain incomplete.

## Verified contention recovery and dependency boundary — 30 October 2026

Full CI [41132406077](https://github.com/kswaroop1/ReMath/actions/runs/41132406077)
passes on `cbca75c1`. A separate connection holds an immediate write transaction
until the operator process exits. Admission returns 74 without changing prior
trust; releasing the lock permits the identical command to succeed, with both
exact keys verified after reopening. This is one deterministic contention/retry
schedule, not process termination, power loss or exhaustive race evidence.

Source-level dependency review at this checkpoint: the signature adapter imports
the existing cryptography package, pinned by pubspec.lock to 2.7.0 with a hosted
archive SHA-256. It delegates Ed25519 verification rather than implementing the
primitive, and receives only public key bytes, payload and signature. Native
composition supplies the SQLite trust store through ContentPackSignatureVerifier;
domain code does not need the cryptography API. This path has no signing service,
private-key handling or network operation. No dependency or lock change is made.

This is a dependency-use/boundary inventory, not a package-source audit or a
current vulnerability, maintenance, licence or all-platform assessment. Those
checks remain required for SP-012 acceptance. Lock integrity and passing public
vectors do not establish supply-chain trust. Successful signed canonical-release
installation, remaining race/failure work, meaningful coverage reconciliation
and independent review remain open.

## SP-012 upstream evidence — 30 October 2026

Checked the locked version's upstream
[package documentation](https://pub.dev/packages/cryptography/versions/2.7.0)
and [licence](https://pub.dev/packages/cryptography/versions/2.7.0/license).
The publisher identifies Apache-2.0 licensing and gohilla.com maintenance.
Its documentation describes multi-platform use and a pure-Dart Ed25519
implementation; these are upstream capability statements, not evidence of
ReMath installation on every target. No additional platform crypto package is
introduced here.

The upstream page identifies 2.9.0 as newer than the locked 2.7.0. Therefore
the existing lock is reproducible but must not be described as current merely
because CI passes. A direct newer-version changelog fetch failed in this review;
no claim is made about intervening fixes or absence of vulnerabilities.
Before SP-012 acceptance, compare intervening changes/advisories against this
verification use and record either an evidenced retention decision or a separate
tested dependency update. No speculative lock upgrade is included.

Latest records checkpoint `ca024d67` passes full CI
[41138567725](https://github.com/kswaroop1/ReMath/actions/runs/41138567725).
SP-012, signed-installation acceptance and independent review remain open.

### Intervening release-note review — 30 October 2026

The canonical [upstream changelog](https://pub.dev/packages/cryptography/changelog)
was accessible after the version-specific URL failed. Between locked 2.7.0 and
advertised 2.9.0 it lists WASM/JS-interop support (2.8.0), unspecified bug fixes
(2.8.1), and Web Crypto Ed25519/X25519 support plus fixes/refactoring (2.9.0).
These notes identify browser-backend changes relevant to future cross-platform
verification; they do not identify every corrected defect or establish whether
2.7.0 is affected by a security issue. Retaining 2.7.0 is not yet a completed
security disposition.

The upstream GitHub advisory page returned DisabledError through the research
tool. No alternate access route was attempted and no clean advisory result is
claimed. Advisory assessment and detailed fix applicability remain unresolved;
other authorized implementation work is not blocked by that single lookup.
Current records head `352fe75f` passes CI
[41144742039](https://github.com/kswaroop1/ReMath/actions/runs/41144742039).

## Review correction checkpoint — 31 October 2026

Full CI [41175694203](https://github.com/kswaroop1/ReMath/actions/runs/41175694203)
passes on `4b87490c`. Enrollment now uses a savepoint around revocation lookup,
validation, insertion and result validation, rolling back on refusal. The
deterministic insertion-time revocation fixture preserves the original unique
key after reopening. Caller-owned transactions remain caller-owned. This is
candidate evidence for review finding 4430247170, not independent acceptance.

### Next blocking activation contract (4430247175)

Inspection confirms activateAtomically already executes pointer/dependency
updates inside the SQLite backend's synchronous transaction. Final trust
authorization must participate in that same transaction, using the exact key
bytes authorized by the earlier signature check, not merely any currently
trusted bytes or an asynchronous check before activation.

Required regression schedules: after initial cryptographic authorization but
before activation, commit (a) revocation, (b) another publisher claim for the
same key ID. Both must refuse activation, preserve the previous active pointer
and bundled fallback, and leave staging recoverable/discarded. Unchanged trust
must retain the successful activation path. Use deterministic barriers or
boundary doubles rather than timing sleeps; do not claim doubles prove the
remaining real signed canonical-installation journey.

An Ed25519-only post-await check is insufficient: streamed payload validation
and staging can still separate it from activation. Keep the finding open until
transaction-coordinated enforcement, negative interleaving tests and independent
review pass. No new signing credentials or implicit trust admission is permitted.
