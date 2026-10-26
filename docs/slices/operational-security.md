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

- Resolve the archive verifier's key-only identity boundary against the store's
  publisher/key pair without ambiguous cross-publisher lookup.
- Ed25519 verification, cryptographic negative cases, and production-composed
  installation coverage using durable trust.
- Explicit operator onboarding/rotation path and concurrency/failure hardening.
- Threat model, dependency security assessment, feature-register reconciliation,
  coverage review and explicit independent review.

PR28 remains draft. SP-006 and CP-005 remain incomplete. No signing credentials,
release, VERSION change or merge is included.
