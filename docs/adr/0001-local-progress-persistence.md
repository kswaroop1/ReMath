# ADR 0001: Local progress persistence

- Status: Accepted
- Date: 27 August 2026

## Context

ReMath must record attempts immediately, resume interrupted sessions, merge
immutable events safely in future, and operate offline on Android, iOS, Windows,
and macOS. The domain must not depend on a storage technology.

## Decision

Use SQLite for native local progress persistence through `package:sqlite3`
3.5.2, with application-support paths supplied by `path_provider` 2.1.6.

All storage is exposed through the pure-Dart `ProgressRepository` interface.
Schema creation is versioned from the first release. Attempt events use their
event ID as the primary key so duplicate insertion is harmless. One active
session snapshot stores the deterministic seed, question index, start instant,
and answer draft.

The optional web target uses an in-memory adapter in this milestone. Persistent
web storage is not claimed as complete.

## Consequences

- Native targets get a durable, transactional data store with no backend.
- Domain and presentation tests can use the in-memory adapter.
- SQLite repository tests use an isolated in-memory database.
- Direct SQLite calls are currently synchronous and must move to a background
  isolate before data volume or measured latency warrants it.
- A later move to Drift remains an internal data-layer change.
- Real schema upgrades require explicit forward migration tests before the
  schema version is incremented.

## Dependency review

Both packages support the required native platforms, are maintained by verified
publishers, and use permissive licences. SQLite data remains on the device and
neither package introduces analytics or network transfer.
