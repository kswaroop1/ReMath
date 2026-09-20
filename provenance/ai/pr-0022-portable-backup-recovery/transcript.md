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
