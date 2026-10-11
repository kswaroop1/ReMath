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
application, and data contracts. Each behaviour has a test-first red commit, a
paired green implementation, and permanent CI replay of the intended red
failure. Authoritative CI run `38138260415` verifies the final behavioural head
with canonical formatting, fatal static analysis, bundled-content validation,
eight Chrome contracts, all 472 native tests, 96.77% line coverage, and secret
scanning. The measured coverage remains 6.77 percentage points above the 90%
repository floor after adding the production-composed payload verifier,
content-addressed sealed staging, atomic activation/removal/first-load
transitions, and their concurrency tests.

CP-005 remains deliberately partial: archive length, SHA-256, and signature
verification are complete, while publisher trust-root lifecycle operations stay
assigned to PR #25 as specified above.

