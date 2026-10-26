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

## Key validation green and bounded identities — 25 October 2026

Exact-head CI `40167573761` passes the complete workflow on `c2f959ac`,
including malformed-key replay and validation. Next acceptance rule makes local
trust identities bounded and unambiguous: publisher and key IDs must not be
empty, whitespace-only, padded with whitespace, or longer than 128 characters.
Added a test for both identity fields before implementing validation. This
concretizes the existing bounded public-input contract, without adding a new
feature. Production code is unchanged; CI must establish the intended red before
its fix. Rotation, revocation, durable storage and cryptographic composition
remain outstanding; PR28 is not ready for independent final review.

## Bounded identity red and fix — 25 October 2026

CI `40172560433` proves the intended identity red: expected ArgumentError, but
enrollment returned null. It also reports formatting drift in the same test
file. The separate fix rejects empty, padded and over-128-character IDs before
trust mutation. Test-only head `ea7750d1` is retained in permanent replay.
Added a temporary non-mutating formatter-output diagnostic for the known test
formatting issue; the fatal gate remains unchanged. Retrieve exact output and
remove diagnostic before authoritative verification. Full green remains pending.

## Identity validation formatter recovery — 25 October 2026

Diagnostic run `40174772596` passes all 531 native tests, including identity
validation, and prints canonical source for the sole formatting failure. Applied
the exact timestamp-stripped output (multiline identity fixture list), with no
assertion changes, and removed the temporary diagnostic. Fatal formatting and
all other gates remain intact. Replacement full CI is pending; production
rotation, revocation, persistence and signature verification remain outstanding.

## Identity green and revocation test — 25 October 2026

Exact-head CI `40179094771` passes the full workflow on `0e3b1406`, with all
531 native tests. Next SP-006 contract: revoking an enrolled key makes it
untrusted and subsequent enrollment cannot restore that key identity. Added a
minimum compiling revoke seam that throws `SP-006 key revocation is not
implemented`, then its business test; no production revocation is implemented.
CI must establish the intended red before the fix. These two preliminary commits
contain only the necessary seam and test, not passing production behaviour.
Durable revocation after restart remains a later storage integration test.

## Revocation verified red and implementation — 25 October 2026

CI `40184101171` reports the intended UnimplementedError for SP-006 key
revocation on test-first head `cc0aab49`. Implemented in-memory irreversible
revocation by key identity: lookup denies revoked identities and enrollment
cannot restore them. Retained the observed red in permanent replay. Persistence
across restart, key lookup for actual signature verification and production
composition remain unimplemented; no durable revocation claim is made.
Replacement full CI is pending.

## Revocation green and durable trust seam — 25 October 2026

Exact-head CI `40189773981` passes the full workflow on `1649a49f`.
Next SP-006 example explicitly enrolls a public key, closes the actual SQLite
connection, reopens the same file, and expects trust to survive. Added only a
minimum CommonDatabase seam (enroll throws `SP-006 durable trust is not
implemented`; lookup denies) and its restart test. No persistence behaviour is
implemented yet. Test temporary storage is isolated and cleaned after closing.
CI must establish intended red before implementation; durable revocation and
transaction failure coverage will follow separately.

## Durable enrollment red and first persistence candidate — 25 October 2026

CI `40193026626` proves intended red `SP-006 durable trust is not implemented`
on test-only head `6217fc83`. Added a SQLite table keyed by publisher/key ID,
validated public bytes using the domain policy, inserted enrollment atomically
with SQLite's single-statement guarantee, and matched stored bytes after reopen.
Permanent replay retains that red. This only implements the first restart
example; duplicate enrollment, durable revocation, rollback and concurrency
contracts remain separate upcoming tests. No full trust-store completion is
claimed. Replacement full CI is pending.

## Durable enrollment green and duplicate test — 25 October 2026

Exact-head CI `40197252913` passes all gates on `948ea2ea`, establishing the
first SQLite enrollment/restart example as green. Added the next test-only rule:
identical enrollment through a second connection to the same database succeeds
idempotently and preserves trust. This is a cross-connection duplicate example,
not a claim of simultaneous concurrent execution. Production code is unchanged;
CI must establish the intended unique-key failure before implementation.
Durable conflict rejection, revocation and failure/concurrency coverage remain.

## Durable duplicate verified red and fix — 25 October 2026

CI `40202015954` proves the intended duplicate red on `566b8568`: SQLite
reports UNIQUE constraint failed for publisher/key identity on the second
connection's identical enrollment. Changed insertion to targeted ON CONFLICT
DO NOTHING, then verify that the existing public bytes match; no row replacement
is used. A mismatch is reported as StateError without overwriting stored trust.
Permanent replay retains the exact observed unique-constraint failure. Full
replacement CI is pending; cross-connection duplicate handling is not a claim
of simultaneous concurrency or durable revocation completion.

## Duplicate enrollment behavioural green — 25 October 2026

CI `40204130926` passes all 534 native tests, including cross-connection
idempotent enrollment. The sole failed step is formatting of
`test/features/learning/data/sqlite_publisher_trust_store_test.dart`; subsequent
analysis/browser/content/coverage enforcement did not run. Added a temporary
non-mutating exact formatter-output diagnostic for that one file; the fatal
gate is unchanged. Apply its exact output and remove the diagnostic before
claiming full green. No durable revocation or concurrent-race guarantee is
claimed by this result.

## Durable duplicate exact formatting recovery — 25 October 2026

Diagnostic CI `40213160335` passes all 534 native tests and provides canonical
SQLite trust-test source. Applied its exact timestamp-stripped output without
assertion changes; removed the temporary diagnostic and retained fatal formatting.
Replacement full CI is pending. No production behaviour changed in this recovery.

## Durable duplicate green and revocation restart test — 25 October 2026

Exact-head CI `40217341712` passes the complete workflow on `740ee308`.
Added the next SP-006 test: enroll, revoke, close SQLite, reopen, then verify
both denial of trust and rejection of re-enrollment. The minimum revoke seam
throws `SP-006 durable revocation is not implemented`; no persistence behaviour
for revocation is present. CI must establish intended red before implementation.
The test includes finally-close protection and isolated temporary storage.

## Durable revocation verified red and implementation — 25 October 2026

CI `40223553022` proves intended red `SP-006 durable revocation is not
implemented` on test-only head `095d11f5`. Added a separate durable revocation
tombstone table; lookup denies tombstones and enrollment rejects them. Revoke
uses a single idempotent insert. Existing public-key records are retained, not
replaced or deleted. Permanent replay retains the observed red. Replacement
full CI is pending. Concurrent enrollment/revocation ordering and direct-store
immutability still require focused tests; this is not a complete concurrency
or production security claim.

## Durable revocation green and verification key lookup — 25 October 2026

Exact-head CI `40230429890` passes the complete workflow on `a9eafade`,
including durable revocation replay, formatting, analysis, browser contracts and
coverage enforcement. No independent review has occurred; PR28 remains draft.

Next SP-006/CP-005 boundary: the signature verifier needs public bytes resolved
by both publisher and key identity, with unknown and revoked identities denied.
Added a focused business test and only a minimum compiling lookup seam returning
null. This is not a working verifier or a production composition change.
CI must establish the intended trusted-key lookup assertion failure before
implementation. Local Flutter was not executed. Existing domain and persistent
trust behaviour is unchanged; concurrency hardening remains outstanding.

## Trusted lookup verified red and candidate — 25 October 2026

CI `40235118927` on `86a33d98` proves the intended lookup failure:
expected enrolled public bytes, actual null, Which: is not Iterable.
It also reports formatting drift in the SQLite trust test. The separate
production commit `4d11dd27` resolves exact publisher/key identity from SQLite,
denies revoked or unknown identities, and returns an unmodifiable byte copy.
No signature verification or production composition is claimed.

Retained the test-first head in permanent red replay. Added a non-mutating
formatter-output diagnostic before the unchanged fatal formatter gate; apply its
exact output and remove the diagnostic before full-green verification. Replacement
CI is pending. Concurrency hardening and independent review remain outstanding.

## Trusted lookup formatting recovery — 25 October 2026

Diagnostic CI `40239583181` passes the native test job step, secret scanning
and permanent red replays. Formatting is its sole failed step; subsequent
analysis/browser/content/coverage enforcement was skipped, so this is not full
green. Applied exact timestamp-stripped canonical SQLite trust-test output from
that run, without assertion changes, and removed the temporary diagnostic.
The fatal formatter remains intact. Replacement full CI is pending.

## Lookup full green and rotation characterization — 26 October 2026

Exact-head CI `40244661696` passes the full workflow on `ed8ef977`.
Added characterization coverage for existing explicit rotation behaviour:
admitting a new key preserves both identities until the old identity is
explicitly revoked, and revoking the old key does not revoke the new one.
No production code changes or manufactured red failure are involved; this is
the existing-behaviour coverage exception in AGENTS.md, not a new implementation
cycle. Replacement CI must verify the characterization.
Cryptographic verification, production composition, concurrency hardening and
independent review remain outstanding. PR28 stays draft.

## Rotation full green and signature boundary inspection — 26 October 2026

Exact-head CI `40249148397` passes on `ede0c5c8`, including the existing
rotation characterization. PR28 has no review comments and remains draft.

Inspected the durable current archive verifier before cryptographic integration:
ContentPackSignatureVerifier.verify receives publisherKeyId, payload and
signature, but no separate publisher identity. The canonical release payload
likewise includes publisherKeyId without publisherId. The trust store instead
binds the pair (publisherId, keyId). Integration must not silently resolve an
ambiguous key ID across publishers or infer operator trust from pack metadata.
The next test-first contract must make that identity binding explicit before
wiring Ed25519 verification. No interface or production behaviour was changed
during this inspection. Signature verification, production composition and
independent review remain outstanding.
