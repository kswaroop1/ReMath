# PR28 chronological AI contribution record

## 24 October 2026 — User

“Was merged” (referring to PR24). The standing authorization is to continue the
accepted infrastructure programme with operational security in a separate PR,
strict test-first red/green commits, full CI, chronological provenance and explicit
independent review. The user handles merges. No release, VERSION change, signing
credentials, subagents or unprioritized content is authorized.

## Assistant — Recovery and acceptance contract

Verified PR24 is merged at `6e187b0b19d83c65681bfc46783f567ee0ea5e42`.
GitHub open-PR search returned no open PRs. Read AGENTS.md, roadmap, feature
register, content-pack lifecycle slice, provenance guidance and the existing
production verifier/composer. The production signature verifier is deliberately
unconfigured and rejects all external signatures; SP-006 and CP-005 remain open.
The roadmap's historical “PR25” label denotes this slice, but the actual newly
allocated draft is PR28. Published acceptance contract commit `4a31cb8f`.

Routine tool output is summarized here. A local git fetch recovered the exact
merge commit; local git push failed because no HTTPS username was configured.
Used the already-configured GitHub connector instead, without extracting or
adding credentials. No user work was changed and no parallel agent was used.

## Assistant — First test-only onboarding boundary

Added one business test: trust is absent until explicit local onboarding, then
matches only the exact publisher, key identity and public bytes. Introduced only
the minimum compiling public seam: enrollment throws the distinctive
`SP-006 publisher onboarding is not implemented` error; lookup returns false.
There is no production implementation that makes the positive example pass.
The fixture contains public bytes only, not a private signing credential.

Focused red command intended for permitted GitHub CI:
`flutter test -r expanded test/features/learning/domain/publisher_trust_store_test.dart`.
Local Flutter execution remains blocked under the standing boundary and was not
attempted. No observed red or green result is claimed yet; CI must establish the
intended failure before implementation. All remaining acceptance criteria,
production composition, durable storage and review remain pending.

## CI diagnosis — 24 October 2026

CI run `40132439345` on red head `5e22f53a` ran the complete native
suite despite an earlier replay failure: 527 tests passed and the sole failure
was the new onboarding test, with the intended `UnimplementedError: SP-006
publisher onboarding is not implemented`. This establishes observed red evidence;
it is not a green or complete gate result. Secret scanning passed.

The separate historical content-lifecycle replay gate failed before testing:
`fatal: invalid reference: 4ec790524530f1feb868ab60a404769d39f6fe68`.
PR24 was squash-merged, so checkout of main no longer includes its intermediate
red commits. Do not delete or weaken replay assertions. The next CI correction
must explicitly fetch the preserved PR24 history before replay (and verify the
historical SHAs), then retain the new onboarding red commit for replay as well.
No production trust implementation or independent review is claimed yet.

## Assistant — First onboarding green candidate

After observed red `5e22f53a`, implementation commit `7885029f` records an
immutable copy of explicitly enrolled public bytes and matches the publisher,
key identity and byte sequence. This is only the first in-memory onboarding
example, not the full security contract. Conflict rejection, input validation,
rotation, irreversible revocation, persistence, cryptographic verification and
production composition still require their own test-first cycles.

CI correction `9084d5c8` fetches preserved `refs/pull/24/head` before replay,
checks the known reviewed PR24 head is available, and adds the PR28 onboarding
red commit to permanent replay without removing historical assertions.
Replacement CI is pending; no green result or review readiness is claimed.

## CI follow-up — 25 October 2026

Exact-head CI `40138266079` restores all historical lifecycle red replays and
passes the new onboarding replay, committed structure and unchanged dependency
lock. All 528 native tests pass, establishing the first onboarding green result.
Secret scanning passes. Formatting reports one changed file, the onboarding test;
subsequent analysis, content/browser checks and coverage-floor gate were skipped.
The local helper invocation is collapsed to the formatter's short single-line
shape; replacement full CI is required. This is not a full-green claim.

## CI follow-up — canonical formatting still unresolved

CI `40144023973` again passes historical and onboarding red replay, structure,
dependency lock, secret scan and all 528 native tests. The attempted manual
format correction was insufficient: the same test file still differs from the
canonical formatter. The earlier wording that formatting was corrected was a
candidate change, not a verified result. Do not guess another layout.

Diagnostic commit `f467f119` adds `dart format --output=show` for the exact
failing file before the unchanged fatal formatting gate. This prints canonical
source without writing it or weakening checks, using permitted CI because local
Flutter execution is blocked. Retrieve that output, apply its exact source, then
remove the diagnostic before the authoritative full run. No new behaviour,
full-green status or independent review is claimed.

## Exact formatter recovery — 25 October 2026

Diagnostic CI `40146579494` printed canonical onboarding test source. Applied
that exact timestamp-stripped output, including the multiline test invocation
and continuation indentation, without changing assertions. Removed temporary
formatter-output diagnostic; fatal formatting remains unchanged. Red replay and
528 native tests passed in the diagnostic run; full replacement CI is pending.

## Verified baseline and next test — 25 October 2026

Exact-head CI `40154960825` on `1abd6df2` passes the full workflow after exact
formatter recovery. The first onboarding example is green with 528 native tests.
This does not complete SP-006 or make the draft review-ready.

Next acceptance rule: onboarding cannot replace public bytes under an existing
publisher/key identity, and rejection preserves original trust. Added a focused
test expecting StateError on conflicting enrollment and original bytes still
trusted. Production code is unchanged; it currently overwrites that identity.
CI must establish the intended assertion failure before the corresponding fix.
No new red result is claimed yet. Remaining validation, rotation, revocation,
persistence, crypto integration and independent review are still outstanding.

## Identity-conflict red and green candidate — 25 October 2026

CI `40158782803` verifies the intended red: the new onboarding conflict test
expected StateError but enrollment returned null. Formatting, analysis, content,
browser, historical replay and secret gates passed; the native suite failed only
for the new rule. Published test-only head `0d9d8f90` is retained for replay.

The separate fix rejects conflicting bytes before changing enrolled trust and
leaves equivalent repeat enrollment unchanged. The existing test also checks the
original bytes remain trusted after rejection. Added permanent replay matching
the observed `Which: returned <null>` failure. Replacement full CI is pending;
no green result or completion of the wider trust lifecycle is claimed yet.

## Conflict green and malformed-key red candidate — 25 October 2026

Exact-head CI `40161487113` passes the full workflow on `928e60d0`, including
permanent onboarding/conflict red replay and the key-conflict preservation fix.
Next SP-006 rule: an Ed25519 public key must contain exactly 32 byte values;
empty, short, long, negative and greater-than-255 inputs must be rejected without
acquiring trust. Added a behaviour-focused test for these cases before any
production validation change. CI must establish the intended red failure before
the fix; no red result is claimed yet. This validates encoding shape, not curve
point validity, which remains the cryptographic verifier's responsibility.

## Malformed-key verified red and fix — 25 October 2026

CI `40166238309` proves the intended malformed-key red: expected ArgumentError,
but enrollment returned null. Formatting, analysis, browser/content, historical
replay and secrets passed. The separate production fix checks exact 32-byte
length and byte range before modifying trust. Preserved test-only commit
`a4603e2e` in permanent replay. Existing valid enrollment and identity-conflict
rules are unchanged. Replacement full CI is pending; no green result is claimed.
