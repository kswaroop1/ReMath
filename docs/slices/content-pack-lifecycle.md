# Content-pack lifecycle slice

PR #24 turns the existing bundled-pack parser and validator into a safe local
content-pack lifecycle. It remains offline-first and provider-neutral: packs may
arrive through a local file or a later catalogue adapter, but activation never
depends on a network service.

## Feature scope

- **CP-002 — Pack manifest parser:** add distribution metadata for compatibility,
  dependencies, sizes, SHA-256 integrity, and publisher signatures while keeping
  the bundled schema-v1-to-v3 foundation pack readable.
- **CP-004 — Pack validator:** reject incompatible, malformed, oversized,
  incomplete, or dependency-incoherent distribution manifests before payload
  activation.
- **CP-006 — Transactional installation:** stage, verify, and activate a complete
  sealed pack atomically, with capacity reserved across concurrent installs and
  dependency state revalidated at activation; a failed install leaves the
  active version unchanged.
- **CP-008 — Offline retention controls:** support explicit pin, update, and safe
  removal decisions without silently changing pinned content or removing packs
  required by active dependants.
- **CP-010 — Storage forecast:** expose compressed, installed, and additional
  required bytes before installation.
- **CP-011 — Pack catalogue:** expose available, installed, update-available,
  pinned, incompatible, and failed states with prerequisites and objectives.
- **CP-012 — Stable-ID progress retention:** removing or rolling back curriculum
  never deletes personal attempt or progress events.
- **CP-013 — Pack rollback:** retain the previous verified version and restore it
  when activation or the first runtime load fails, while an atomic first-load
  confirmation prevents an older load from overwriting a newer activation.

## Learner and operator acceptance criteria

- A catalogue can be loaded offline and reports honest compatibility, version,
  dependency, download-size, installed-size, and storage-impact information.
- A selected pack is read into bounded staging storage, then its length,
  SHA-256 digest, publisher signature, schema, references, dependencies, and app
  compatibility are verified before any active pointer changes.
- Installation, update, removal, pinning, and rollback are idempotent and survive
  interruption. The active version is either the previous verified version or
  the complete new verified version, never a partially installed pack.
- Native production composition persists staged/sealed objects, reservations,
  active and retained versions, dependency edges, cleanup obligations, and
  first-load generations in SQLite so those guarantees span process restarts.
- A pinned pack is not automatically updated or removed. Explicit unpinning or a
  specific version choice is required before replacement.
- Removing or rolling back a pack changes curriculum availability only. Stable
  skill/question history remains in the personal-progress repository.
- A runtime-load failure restores the previous verified version and records an
  actionable local status without exposing payload or personal data.
- Legacy bundled schema-v1-to-v3 packs remain readable and the current bundled
  foundation pack remains the safe fallback.
- Tests cover invalid metadata, digest/signature failure, insufficient storage,
  missing dependencies, duplicate requests, interruption, rollback, pinning,
  removal, and retained progress.

## Explicitly out of scope

- Network catalogues, provider OAuth, background downloads, and cloud sync.
- Publisher onboarding, trust-root distribution, key rotation or revocation,
  transparency logs, and broader operational-security policy (PR #25).
- Delta updates, pack authoring UI, new curriculum, release publication,
  signing credentials, and any `VERSION` change.

## Delivery evidence

The bounded lifecycle behaviours are implemented as provider-neutral domain,
application, and data contracts. Focused red/green evidence and permanent replay
cover the behavioural gaps, with the historical evidence limitations below
recorded explicitly rather than rewritten. Authoritative CI run `38693526874`
verifies the final twelfth-review behavioural head with permanent red replay,
canonical formatting, fatal static analysis, bundled-content validation, eight
Chrome contracts, all 526 native tests, 96.66% line coverage, and secret
scanning. The measured coverage remains 6.66 percentage points above the 90%
repository floor.

The sixth-review corrections make sealed parent state immutable, preserve
truthful atomic duplicate outcomes, bind pinning to observed activation state,
provide the SQLite lifecycle composer, preserve primary staging failures,
distinguish live reservations from abandoned restart state, and reject active
dependency cycles. The sixth-round composer red did not assert the native
`main.dart` startup wiring added by its green, so that wiring is not claimed as
test-first. The seventh-review corrections add append-only staging, durable
capacity accounting, process-unique reservation ownership, canonical semantic
versions, release-derived app compatibility, and a production startup loader
that confirms or rolls back durable active content before `runApp`; all six new
red heads are permanently replayed by CI. The historical fifth-review evidence
finding also remains explicit: four genuinely test-first behaviours were
batched into one published red/green pair rather than separate pairs. Published
history has not been rewritten or misrepresented.

The eighth-review corrections prevent deletion from staging before sealing,
make repeated unpinning truthfully unchanged, recover every pending first-load
activation, retry generation-checked recovery after concurrent activation, and
close failed optional lifecycle storage before starting with the bundled
foundation pack. All five behavioural corrections have separate published red
and green commits and permanent red replay.

The ninth-review corrections coalesce empty and tiny source chunks into bounded
64-KiB staging rows and atomically retire dependency snapshots with the pack
versions they describe. Both corrections have separate published red and green
commits and permanent red replay; the omitted eighth-round records-head CI is
also restored to the chronological provenance metadata.

The tenth-review corrections guard staging parents from cascade deletion,
lease reservation ownership across separate live SQLite connections, reject an
oversized source chunk before copying it, and preserve dependencies required by
a previous version while a newer activation awaits its first load. All four
behavioural corrections have separate published red and green commits and
permanent red replay; the omitted ninth-round records-head CI is restored to
the chronological provenance metadata.

The eleventh-review corrections reclaim reservations when leases expire during
the current process, preserve both sides of a pending rollback dependency set
during replacement, and prevent SQLite replacement conflict clauses from
bypassing append-only staging object and chunk storage. All three behavioural
corrections have separate published red and green commits and permanent red
replay; the omitted tenth-round records-head CI is restored to the chronological
provenance metadata.

The twelfth-review corrections make reservation identity and accounting fields
immutable at the shared SQLite boundary and persist an explicit activation order
so restart selects the pack activated most recently even after an earlier row is
updated. Both behavioural corrections have separate published red and green
commits and permanent red replay; the omitted eleventh-round records-head CI is
restored to the chronological provenance metadata.

CP-005 remains deliberately partial: archive length, SHA-256, and signature
verification are complete, while publisher trust-root lifecycle operations stay
assigned to PR #25 as specified above.
