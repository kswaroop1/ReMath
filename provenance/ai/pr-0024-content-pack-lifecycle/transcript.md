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
