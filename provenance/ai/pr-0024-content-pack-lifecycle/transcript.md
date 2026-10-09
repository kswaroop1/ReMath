# AI assistance record — PR #24 content-pack lifecycle

## 2026-10-08 — Scope recovery and acceptance contract

The automation verified that PR #22 merged into `main` at commit `a53344e` and
that no pull request remained open. It recovered `AGENTS.md`, the feature
register, roadmap, content-pack documentation, existing parser/validator code,
and the accepted sequence naming content-pack lifecycle as the next feature PR.

The assistant bounded the slice to CP-002, CP-004, CP-006, CP-008, CP-010,
CP-011, CP-012, and CP-013. Digest and publisher-signature verification belong
to the activation boundary, but publisher onboarding, trust-root distribution,
key rotation/revocation, network catalogues, OAuth, delta updates, release work,
credentials, and `VERSION` changes remain excluded. This contract was committed
before the first test-only commit as required by `AGENTS.md`.

GitHub assigned the lifecycle branch PR #24 because closed Dependabot PR #23 had
already consumed the preceding number. The documentation and provenance path
were corrected immediately; operational security therefore follows as PR #25.

## 2026-10-08 — CP-002 distribution manifest red

The first behaviour test describes the complete offline install decision:
identity/version, learner-facing catalogue metadata, compatibility, sizes,
digest, publisher key identity, signature, dependencies, and objectives. The
test-first commit contains only the public immutable data shape and a parser
that deliberately throws `UnimplementedError`; parsing behaviour is absent so
the focused test is expected to fail until its paired green commit.

CI run `37799001302` executed the red head `4ec7905`. The focused test failed
with `UnimplementedError: Content-pack release parsing is not implemented`, as
intended; the existing 424 tests passed and the secret scan passed. The same run
also reported canonical-formatting changes in the new parser and test, which are
applied with the paired implementation rather than weakening the format gate.

Green-head CI `37799444308` passed all 425 tests and the secret scan; only the
two new files differed from Dart 3.13 canonical formatting. Because the local
Flutter/Dart runtime is unavailable, a temporary least-privilege diagnostic
workflow prints that exact two-file formatter patch. It will be removed in the
same correction that applies the output.

GitHub does not start a newly introduced pull-request workflow until it exists
on the base branch. The unused diagnostic file was therefore removed, and the
existing CI format step was temporarily changed to format then fail on `git
diff`, which prints the same bounded patch without changing permissions or any
later quality gate.

Diagnostic run `37800073565` printed the exact Dart 3.13 patch. The two source
files now match it byte-for-byte, the temporary workflow is absent, and the
ordinary non-mutating format gate is restored for replacement full CI.

Replacement full CI `37800365348` passed the committed application structure,
dependency lock, canonical formatting, fatal warnings/infos analysis, bundled
content validation, 8 Chrome contracts, 425 native tests, the 90% coverage gate
at 97.15% line coverage, and secret scanning on head `8bbb7c3`. CP-002's first
manifest-reading behaviour is therefore green; invalid-manifest validation and
the remaining lifecycle behaviours stay deliberately incomplete.

## 2026-10-08 — CP-004 distribution validation

Test-only commit `d806655` specifies aggregate rejection of unsupported manifest
versions, malformed identifiers and semantic versions, unsafe sizes, invalid
licences and languages, malformed integrity metadata, duplicate/self
dependencies, and missing objectives. Green commit `2f1049b` implements the
provider-neutral validator. The permanent focused evidence gate checks out the
red commit and requires the intended `CP-004 release validation is not
implemented` failure before testing the branch head.

CI formatting diagnostics were needed because the repository's Dart runtime is
unavailable locally. Final run `37808072288` verifies canonical formatting,
fatal static analysis, content validation, eight Chrome contracts, all 427
native tests, 97.14% line coverage, and secret scanning.

## 2026-10-08 — CP-010 storage forecast

Test-only commit `b5ef673` defines compressed, installed, reclaimable, and
additional-required byte calculations, including invalid negative capacity.
Green commit `75a16f9` implements the immutable forecast policy, and evidence
commit `e8353fc` permanently replays the intended `CP-010 storage forecast is
not implemented` red failure.

Full CI `37816912618` passes every gate with eight Chrome contracts, all 429
native tests, 97.15% line coverage, and secret scanning.

## 2026-10-08 — CP-011 offline catalogue state

Test-only commit `8b31697` defines the available, installed, update-available,
pinned, incompatible, and failed catalogue states and their learner-facing
prerequisite, objective, version, and failure metadata. Green commit `ddb80f5`
implements deterministic semantic-version classification. The CI evidence gate
requires the red head to fail with `CP-011 catalogue states are not implemented`.

An initial run identified only canonical formatting. Commit `2bcf55d` applies
the exact CI formatter output; replacement run `37831858412` passes every gate
with eight Chrome contracts, all 431 native tests, 97.13% line coverage, and
secret scanning.

## 2026-10-08 — CP-006 transactional installation

Test-only commit `9fa2928` specifies stage-verify-activate ordering, preservation
of the active pack after verification failure, staged-data cleanup, and
idempotent duplicate installation. Green commit `36332cf` implements the
application coordinator and atomic store boundary. Permanent red replay checks
the expected `CP-006 transactional installation is not implemented` failure.

The first head run exposed canonical formatting only. Commit `0ae3baa` applies
that output; full CI `37840720210` passes every gate with eight Chrome contracts,
all 434 native tests, 97.13% line coverage, and secret scanning.

## 2026-10-08 — CP-006 archive integrity and publisher signature

Test-only commit `32758dd` specifies archive-length, SHA-256, malformed-signature,
and untrusted-signature rejection before activation. Green commit `7ab7d03`
implements SHA-256 verification and a provider-neutral publisher-trust seam.
Follow-up test commit `a52ce85` correctly awaits asynchronous failures without
changing the contract. Permanent red replay requires the intended `CP-006
archive verification is not implemented` failure.

Commit `0a86155` applies canonical formatting. Full CI `37847622945` passes every
gate with eight Chrome contracts, all 438 native tests, 97.10% line coverage,
and secret scanning. No trust root, signing credential, publisher onboarding,
rotation, or revocation behaviour is included; those remain PR #25 scope.

## 2026-10-09 — CP-008 offline retention controls

Test-only commit `2503052` defines idempotent pin/unpin, pinned-update blocking,
explicit pinned-version replacement, and safe removal decisions. Green commit
`79cbc4d` implements the pure retention policy. The permanent evidence step
requires the test-only head to fail with `CP-008 retention controls are not
implemented`.

After one CI formatter diagnostic, commit `1c19a66` matches Dart 3.13 canonical
formatting. Full CI `37866329398` passes every gate with eight Chrome contracts,
all 443 native tests, 97.09% line coverage, and secret scanning.

## 2026-10-09 — CP-012 progress-preserving removal

Test-only commit `ffe48d1` defines the application-level invariant that removal
changes only content availability: it never receives or mutates the personal
progress repository, duplicate removal is idempotent, pinned removal is blocked,
and a failed availability-store write can be retried. Green commit `3bd062a`
implements the remover over the existing retention policy and the narrow
availability boundary. Permanent red replay requires `CP-012
progress-preserving removal is not implemented`.

Commit `27a8cbe` applies the exact CI formatter output. Full CI `37869966133`
passes every gate with eight Chrome contracts, all 446 native tests, 97.10% line
coverage, and secret scanning.

## 2026-10-09 — CP-013 first-load rollback

Test-only commit `18dcc73` specifies successful first load, failed-load rollback
to the retained verified version, payload-safe local failure status, idempotent
recognition of an already recovered pack, and retry after an interrupted restore.
Green commit `96481e9` implements the rollback coordinator. Evidence commit
`6114a18` permanently replays the test-only head and requires the intended
`CP-013 runtime rollback is not implemented` failure.

CI `37871589333` proved all 450 native tests but found one unused optional test
fixture parameter. Commit `c1d37a8` removes it. Replacement run `37871978999`
again passed the behavioural suite and then identified only the canonical
one-line constructor layout; commit `2e0b77d` applies that exact style change.

Authoritative full CI `37872340857` passes project structure, the dependency
lock, canonical formatting, fatal static analysis, bundled-content validation,
eight Chrome contracts, all 450 native tests, the coverage floor at 97.11%, and
secret scanning. The feature register and slice are reconciled in the following
records-only checkpoint before explicit independent review.
