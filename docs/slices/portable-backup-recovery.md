# Portable backup and recovery

## Scope and acceptance (selected before implementation)

PR22 delivers bounded foundations for DS-004, DS-016, DS-017, SP-005 and
SP-012. A learner can create a password-encrypted portable backup of personal
progress, inspect it without changing local data, and recover immutable attempts
through an idempotent merge.

## Backup contract

- Export a canonical, versioned payload containing immutable attempt events,
  the optional active study snapshot and the optional active learning session.
  Standard curriculum content is excluded.
- Encrypt before the bytes leave the application boundary. Use a random salt
  and nonce, a password-derived key, and authenticated encryption so an incorrect
  password or any modified metadata/ciphertext fails closed.
- Include only non-secret preview metadata outside encryption: format/version,
  creation time, algorithm identifiers, salt, nonce, ciphertext and counts that
  are authenticated as associated data. Never store the password or derived key.
- Reject unsupported versions, algorithms, malformed encodings, invalid event
  values, duplicate IDs with conflicting content, and unsafe snapshot data.

## Recovery contract

- Preview decrypts and validates the complete payload, then reports creation
  time, format version, attempt count, new/duplicate/conflicting event counts,
  skill/time range, and whether an active snapshot is present. Preview writes
  nothing.
- Apply merges new immutable events by event ID. Byte-for-byte equivalent events
  are duplicates; the same ID with different immutable content blocks the entire
  import. Retrying an applied backup adds nothing.
- Apply is transactional for SQLite. A validation or write failure leaves local
  attempts and active state unchanged.
- An imported active snapshot is offered only when local active state is empty;
  applying it must not overwrite a local in-progress journey.
- An imported learning session is restored only when no local active session
  exists. Its question position, draft, remediation phase, hint count and seed
  are preserved in the same transaction as attempts and study state. Its exact
  generated question ID and skill are also retained, so a mixed Home session
  cannot resume against a different operation or template version.

## User journey

- A data screen reachable from Home supports export and import on native
  platforms through a provider-neutral file boundary. Web deliberately omits
  the journey until browser progress storage is durable across reloads.
- Export requires password entry and confirmation. Import asks for the password,
  shows the preview, requires explicit apply, and reports the result.
- Empty data, Unicode answers, calibration fields, related event IDs, UTC times,
  interruption, wrong passwords, tampering, duplicate delivery and conflicting
  IDs have focused tests.

## Dependency decision boundary

Cryptography and file-access packages require a recorded maintenance, licence,
platform, privacy and architecture assessment before addition. Crypto remains in
the data layer behind a provider-neutral backup interface; domain rules do not
import packages. No network access or telemetry is introduced.

`file_picker` 13.1.0 is used only by the data-layer adapter. It is actively
maintained, MIT licensed, and supports native open and save journeys on Android,
iOS, Linux, macOS, Windows and web. Selected backup bytes pass directly between
the operating-system picker and the provider-neutral `BackupFileBoundary`; the
package receives no password, derived key, network permission or telemetry.
Flutter's `file_selector` was rejected because save-location selection is not
supported on Android, iOS or web. macOS receives only the user-selected-file
read/write entitlement required for this journey.

`cryptography` 2.7.0 is pinned by the reproducible lock and isolated behind
`BackupCipher` in the data layer. The upstream package is maintained, Apache
2.0 licensed, cross-platform and supplies the Argon2id and AES-GCM primitives
used here. ReMath uses its pure-Dart implementation rather than adding the
optional platform plugin, keeping the dependency surface consistent across the
supported native targets. The package receives the password only inside the
encryption operation, retains no key material, and introduces no network,
account, telemetry or storage permission. Each export uses a fresh secure salt
and nonce; envelope algorithm/version metadata is authenticated, and wrong
passwords or any tampering fail closed. Deterministic random-byte injection is
available only through the test seam. Version 2.7.0 is older than the current
upstream release, so upgrades require a separate compatibility and envelope
interoperability review rather than an unbounded dependency bump.

## Verification

Use separate test-first and implementation commits for each behavior. Record the
red failure, green result, full format/analyse/test/coverage evidence and the
independent Codex review in the PR22 provenance record. Target meaningful line
and branch coverage as close to 100% as practical.
