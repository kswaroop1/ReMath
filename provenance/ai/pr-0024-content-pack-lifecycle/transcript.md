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

Test-only commit `b5ef673` defines compressed, installed, and
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

## 2026-10-09 — Register reconciliation and records-head verification

Records-only commit `64c5d7f` marks the completed CP-002, CP-004, CP-006,
CP-008, CP-010, CP-011, CP-012, and CP-013 contracts in the authoritative
feature register, preserves CP-005 as a deliberately partial verification
foundation pending PR #25 trust operations, adds the slice delivery evidence,
and brings this chronological record through the final behavioural corrections.

Records-head CI `37872829581` passes every repository gate: permanent focused
red replay, committed project structure, dependency-lock verification,
canonical formatting, fatal static analysis, bundled-content validation, eight
Chrome contracts, all 450 native tests, 97.11% line coverage, and secret
scanning. This final records update precedes the explicit independent review
request; it contains no production or test behaviour change.

Records-head CI `38115688317` later repeated the same complete green result at
commit `dfe5890` before the independent review response arrived.

## 2026-10-11 — Recovered exchanges and independent review

The complete interactive export before durable GitHub recovery was unavailable
to this resumed run. No hidden instructions or private reasoning are included.
Routine tool telemetry is summarized above; the material available user,
assistant, and reviewer exchanges are preserved below. This is an explicit
record of the unavailable historical exchanges rather than a claim that the
narrative above is a verbatim transcript.

Available user authorization (verbatim):

> Continue the authorized ReMath infrastructure programme in kswaroop1/ReMath
> from this chat's latest durable GitHub checkpoint. Recover state from open
> PRs, AGENTS.md, docs/features.md, docs/roadmap.md, docs/slices, CI, review
> discussion, and provenance; do not depend on scratch files. Avoid overlapping
> edits with an active run. First finish draft PR21's bounded engineering
> baseline: EN-011 committed reviewed platform runners, EN-012 reproducible
> dependency lock, an EN-019 production-composed critical-journey integration
> foundation, and stable initial EN-020 performance-budget foundations. The
> feature-register reconciliation and acceptance contract are published; CI run
> 34971033181 provides the expected red structure boundary. Generate runners
> only through permitted GitHub CI because local Flutter execution is blocked.
> Follow repository strict test-first separate red/green commits, full CI,
> chronological AI provenance, and explicit independent review. Publish durable
> checkpoints and address CI/review failures. Then proceed through the accepted
> infrastructure sequence in separate reviewable PRs: portable backup/recovery,
> content-pack lifecycle, and operational security, keeping scope bounded and
> reconciling the register as capabilities complete. The user handles merges.
> Do not merge, release, change VERSION, add signing credentials, delegate to
> subagents, or expand into unprioritized content. Respect usage limits,
> retry-after times, approvals, and tool restrictions; never bypass a denial.
> Report substantive progress, review-ready PRs, or blockers needing user
> action. When the accepted infrastructure sequence is complete with passing CI
> and reviewable PRs, report completion and disable this automation.

Available user question (verbatim):

> Is the PR now ready to be merged?

Material assistant response (verbatim):

> PR #24 is not merge-ready yet. The behavioral and records-head CI are green,
> but the required explicit independent review is still outstanding.

The independent Codex review then created 13 unresolved inline findings. Its
material conclusions, preserved without relabelling their severity, were:

1. P1: activation did not compose release validation, compatibility,
   dependencies, capacity, integrity, and content validation
   ([exact review][r1]).
2. P1: verification read caller-owned bytes instead of the exact staged bytes
   ([exact review][r2]).
3. P1: publisher signatures authenticated only the archive digest, not canonical
   release metadata ([exact review][r3]).
4. P2: rollback status could be lost if persistence failed after restoration
   ([exact review][r4]).
5. P1: the CP-002 test-only commit was missing from permanent red replay
   ([exact review][r5]).
6. P1: documentation claimed reclaimable storage that was not implemented
   ([exact review][r6]).
7. P1: rollback could not represent a first installation with no prior version
   ([exact review][r7]).
8. P2: concurrent duplicate installation could stage and activate twice
   ([exact review][r8]).
9. P1: provenance metadata did not conform to the repository schema
   ([exact review][r9]).
10. P1: provenance omitted material exact available exchanges
    ([exact review][r10]).
11. P1: installation required a complete in-memory `List<int>` archive
    ([exact review][r11]).
12. P2: automatic update policy permitted implicit downgrades
    ([exact review][r12]).
13. P1: rollback could overwrite a newer activation without compare-and-swap
    ([exact review][r13]).

The assistant initially described this as "12 substantive items" in a progress
update. That count was incorrect; the durable review contains 13 threads, as
enumerated above. The following test-first correction stack addresses every
thread before requesting another independent review.

[r1]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449508
[r2]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449514
[r3]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449517
[r4]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449521
[r5]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449524
[r6]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449530
[r7]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449536
[r8]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449539
[r9]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449545
[r10]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449547
[r11]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449549
[r12]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449554
[r13]: https://github.com/kswaroop1/ReMath/pull/24#discussion_r4240449557

## 2026-10-11 — Test-first review correction stack

The correction stack was created as five separate test-only/implementation
pairs before the branch reference moved:

- `cb3e8f4` / `3275e6f` streams an archive into bounded staging, verifies the
  exact staged handle, and serializes same-pack installation. The focused red
  failures are `Bounded staged installation is not implemented` and `Bounded
  archive verification is not implemented`.
- `d2f5b86` / `e3eed40` requires the signature boundary to receive canonical
  release metadata containing the verified archive digest. The focused red
  test fails while decoding the old digest-only payload.
- `e356d7b` / `30fae0f` composes manifest validation, app/schema compatibility,
  dependency availability, storage capacity, archive integrity, and content
  validation into the fail-closed activation path. The focused red failure is
  `Content-pack activation policy is not implemented`.
- `039edf7` / `5516e4d` replaces separate restore/status calls with one atomic,
  compare-and-swap rollback transition, including first installs with no prior
  version. The focused red failure is `Atomic first-load rollback is not
  implemented`.
- `26b6d7f` / `0c1e734` rejects implicit semantic-version downgrades while
  preserving explicit version selection. The focused red assertion requires
  `ContentPackRetentionOutcome.blockedDowngrade`.

Commit `428519d` corrects the provenance schema, links every exact review
exchange, records the available exact user and assistant text, and removes the
unsupported reclaimable-storage claim. The CI evidence update permanently
replays all five new red heads and the previously omitted CP-002 red head.

Full CI `38119345720` proves the expanded permanent red replay, committed
structure, dependency lock, all 462 native tests, coverage, and secret scanning.
It reports only seven Dart 3.13 canonical-formatting differences. Because no
local Flutter/Dart runtime is available, the existing format step is changed
temporarily to print the exact formatter patch; the ordinary non-mutating gate
will be restored in the immediate correction commit.
