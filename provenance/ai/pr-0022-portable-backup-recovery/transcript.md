# PR22 — Portable backup and recovery

## User — 20 September 2026

> Merged. Go to next feature set as planned.

## Assistant — selection

The repository and prior agreed infrastructure sequence were reconciled after
PR21 merged. PR22 is the portable backup/recovery slice, followed by content-pack
lifecycle and operational security. The accepted working rules continue:
test-first red/green commits, meaningful coverage near 100%, chronological AI
provenance, green CI, explicit independent `@codex review`, and correction of
review findings before handoff. Merge control remains with the user.

Selected DS-004, DS-016, DS-017, SP-005 and SP-012 foundations. The slice uses
encrypted versioned export, read-only preview, transactional idempotent event
merge and a provider-neutral file boundary. It excludes cloud sync, OAuth,
content-pack transfer, release and VERSION changes.

## Cycle 1 select/red — portable payload

Acceptance: a version-one payload reproduces every immutable attempt field,
orders events canonically, normalizes persisted times to UTC, preserves Unicode
answers and the optional study snapshot, and re-encodes identically. Unsupported
versions, duplicate event IDs and invalid negative response times fail before
any import can occur.

The red commit adds only behavior tests importing the required public payload
seam. The expected red failure is the missing
`features/backup/domain/backup_payload.dart` library; no production behavior is
included in that commit.

CI run 35499113853 failed at the intended missing-library boundary:

```text
Error when reading 'lib/src/features/backup/domain/backup_payload.dart':
No such file or directory
```

The same run also identified canonical formatter changes required in the test.
The green implementation adds only the package-neutral payload codec and its
validation; it adds no encryption, file or import behavior prematurely.

CI run 35499557610 verified the payload implementation.

## Cycle 2 red/green — authenticated encryption

The red contract required password-derived authenticated encryption, no
plaintext leakage, wrong-password and tamper rejection, strict envelope
validation, and injectable salt and nonce sources for deterministic tests. CI
run 35503629845 recorded the expected missing implementation. The green change
used Argon2id and AES-256-GCM, authenticated the security metadata, and committed
the dependency lock. CI run 35515361087 verified the implementation after the
CI-generated transitive lock entry and canonical formatting were reconciled.

## Cycle 3 red/green — read-only import preview

The red contract required a complete decrypt-and-validate pass that writes no
data and reports payload version and creation time, new/duplicate/conflicting
attempt counts, skill and time ranges, and snapshot presence. Conflicting event
IDs must make the preview inapplicable. CI run 35519550576 recorded the expected
red boundary; CI run 35519706225 verified the minimal preview implementation.

## Cycle 4 red/green — transactional recovery

The red contract required idempotent immutable-event union, conflict rejection,
atomic SQLite application, and protection for an existing active study. CI run
35523312758 recorded the expected red behavior. The repository implementations
then applied new events and an eligible snapshot in one transaction, with
equivalent events ignored and any validation or write failure rolling back. CI
run 35525416061 verified the behavior.

## Cycle 5 red/green — application coordinator

The red coordinator contract separated export, preview, and explicit apply,
and rejected unsafe imported snapshot JSON before any write. CI run 35525883597
recorded the red boundary. The implementation composed the codec, cipher and
repository while retaining a validated pending import between preview and
apply. Compatibility and fail-closed error normalization corrections followed;
CI run 35531506867 verified the final coordinator.

## Cycle 6 red/green — provider-neutral file transfer

The red file-boundary contract required a stable `.remath-backup` export name,
safe cancellation, a read-only preview, and explicit application without
leaking provider concerns into the domain or coordinator. CI run 35536035961
recorded the expected red boundary. CI run 35536206303 verified the boundary and
transfer implementation.

## Cycle 7 red/green — learner-facing recovery journey

The widget red contract required matching password confirmation, visible export
success, preview counts without writes, an explicit Apply backup action, and a
visible restored-attempt result. CI run 35537564109 recorded the expected red
boundary. The implementation added the backup-and-recovery screen and isolated
expensive production Argon2 work from widget tests through the existing cipher
seam. CI run 35544999179 verified the journey.

## Cycle 8 red/green — production file selection and navigation

The red integration contract required Home navigation, production coordinator
composition, user-selected open/save handling, safe cancellation, and the
minimum macOS entitlement. CI run 35547974161 recorded the expected red
boundary. The green implementation added a `file_picker` data-layer adapter,
application wiring, and the user-selected-file entitlement. The dependency
lock was regenerated through CI and committed. CI run 35548530327 verified 314
tests at 98.34 percent line coverage, formatting, analysis, content validation,
Chrome contracts, and secret scanning.

The dependency decision records `file_picker` 13.1.0 as actively maintained,
MIT licensed, and able to provide open and save selection across the supported
platforms. It receives encrypted bytes only, no password or derived key, and no
network or telemetry permission. `file_selector` was rejected because its save
journey is unavailable on Android, iOS, and web.

## Cycle 9 red/green — password recovery warning

The acceptance register requires an explicit warning because encrypted backups
cannot be recovered after a password is forgotten. CI run 35551231469 recorded
the focused widget test failing before implementation. The separate green
commit added the visible warning next to the password controls; CI run
35551472718 verifies that final behavior.
