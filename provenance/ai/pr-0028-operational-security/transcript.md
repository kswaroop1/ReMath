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

## Cross-connection conflict characterization — 26 October 2026

Verified unchanged branch head `93d964fb` and passing full CI `40251621658`.
Added existing-behaviour characterization: a second SQLite connection attempting
different public bytes under an enrolled publisher/key identity must receive
StateError, and both connections must still resolve the original bytes.
This exercises the previously implemented duplicate/conflict path without
changing production behaviour or manufacturing a red failure. It does not
simulate simultaneous concurrent writes. Replacement CI is pending.
The signature identity integration gap remains unresolved; this coverage change
does not claim cryptographic verification or production trust composition.

## Conflict green and rollback characterization — 26 October 2026

Exact-head full CI `40258655973` passes on `372ac7b2`, including the
cross-connection conflict preservation test. Added characterization of SQLite's
existing transaction guarantee: begin a transaction, revoke an existing key and
enroll another, roll back, close and reopen, then require the original key to
remain trusted and the new key to remain absent. No production code changes
or manufactured red failure are involved. This tests explicit rollback, not
process-kill or disk-failure simulation. Replacement CI is pending.
Signature integration and independent review remain outstanding.

## Rollback green and acceptance reconciliation — 26 October 2026

Verified exact-head full CI `40264531840` on `3a59875e` passes, including
rollback/reopen characterization. Updated the operational-security slice's stale
acceptance-only checkpoint to distinguish delivered trust-store foundations from
remaining signature integration, operator path, failure/concurrency hardening,
threat model and independent review. Feature completion is not claimed.
This records-only checkpoint changes no production behaviour or tests.

## Malformed persisted trust red contract — 26 October 2026

Full CI `40270225427` passes on checkpoint `879b7175`.
Added the next test-first failure-path rule: malformed public bytes already
present in SQLite must neither resolve for signature verification nor match
isTrusted. The test inserts a two-byte blob to simulate invalid persisted data;
it asserts observable denial, not a specific schema or SQL implementation.
Production code is unchanged. CI must prove the intended missing validation
failure before implementation. This is defensive validation, not protection
against a device attacker who can substitute a valid key or alter the app.
Signature binding, cryptography and independent review remain outstanding.

## Malformed stored key verified red and fix — 26 October 2026

CI `40274711282` on `25822df3` proves intended red: expected null, actual
[1, 2] from trusted lookup. Formatting, static analysis, browser/content checks,
secrets and historical replay passed. Added length validation on both SQLite
lookup paths so non-32-byte stored blobs cannot resolve or match as trusted.
Preserved the observed test-first head in permanent red replay. SQLite BLOB
already provides byte-range values; this change addresses length only, not
curve validity, non-BLOB corruption or compromised-device protection.
Replacement full CI is pending; signature integration and review remain open.

## Malformed length green and stored-type red contract — 26 October 2026

Exact-head full CI `40280926088` passes on `40e9b8ba`.
Added the next failure-path test: a non-BLOB key value in SQLite must return
null/false from trust lookup, without a type-cast exception. SQLite's current
non-strict column permits such persisted values; the test uses the real storage
boundary and asserts safe denial. Production code is unchanged; CI must
establish the intended missing stored-type validation failure before its fix.
This is not a claim of protection against device compromise or of completed
signature integration. PR28 remains draft.

## Stored type verified red and fix — 26 October 2026

CI `40284854853` on `57e7d3da` proves intended red: type 'String' is not
a subtype of type 'List<int>' in type cast. Formatting, analysis, content,
browser, secrets and prior red replays pass. Replaced unchecked casts with
explicit List<int> checks in both public-key lookup paths, denying other stored
types before accessing length or bytes. The original test and observed red
head are retained in permanent replay. Full replacement CI is pending.
This defensive storage validation does not complete signature integration or
independent review; PR28 remains draft.

## Stored-type full green and threat model draft — 26 October 2026

Exact-head full CI `40290599768` passes on `67c72aa0`.
Published the bounded SP-011 threat-model draft in the accepted slice document,
covering malicious packs, trust bootstrap, metadata tampering, replay, key
compromise/rotation, hostile backups, device compromise, credential theft,
supply chain and interrupted/competing operations. It distinguishes required
controls from unfinished implementation and states residual risks explicitly.
No production behaviour, dependency, credential or release changes are included.
Threat-model review and the wider slice acceptance remain pending.

## PR status reconciliation — 26 October 2026

Full CI `40299958198` passes on `4f3d9e82`. No review discussion is present.
Replaced PR28's stale acceptance-only description with verified foundations,
exact CI reference and remaining acceptance gaps. Kept the PR draft; final
independent review is not yet requested for the unfinished slice.
No production behaviour or tests changed in this records-only checkpoint.

## Key-only identity binding red contract — 26 October 2026

Recovered unchanged head `803834a8`, previously verified by full CI
`40308460133`. To bridge the existing signed publisherKeyId without silently
choosing a publisher, selected fail-closed unique resolution: a key ID may
resolve only when exactly one enrolled publisher/key pair has ever claimed it.
Multiple publisher claims remain ambiguous even if their bytes match or one
claim is revoked. Pack metadata still cannot enroll keys or grant trust.

Added only a compiling null-returning lookup seam and a test requiring unknown
denial, unique positive resolution, ambiguous denial and persistent ambiguity
after one claim is revoked. No implementation that makes the positive case
pass is present. CI must prove intended red before implementation. This is a
conservative compatibility boundary, not authorization to treat a key as an
independent publisher claim or to add signing credentials.
Actual Ed25519 verification and production composition remain pending.

## Unique identity verified red and candidate — 26 October 2026

CI `40321316048` on `31f4c516` proves intended red: unique enrolled key
lookup returned null (Which: is not Iterable). Other executable gates except
coverage enforcement passed. Implemented resolution only when exactly one
publisher_trust row claims the key ID, then delegate to validated, non-revoked
pair lookup. Revoked claims remain counted, so ambiguity cannot be removed by
revoking one publisher. No first-match or byte-equality shortcut is used.
Permanent replay retains the test-first head. Replacement full CI is pending.
This synchronous resolution foundation does not yet wire Ed25519, establish
simultaneous race safety, or complete production composition.

## Ed25519 verification red contract — 26 October 2026

Unique key resolution passes full CI `40330349563` on `6e02f179`.
Added a minimum ContentPackSignatureVerifier implementation returning false and
a positive test using RFC 8032 section 7.1 TEST 1's public key, empty message
and published signature. Verified fixture against the RFC Editor text source.
No private seed/key is included or generated. No cryptographic implementation
is present yet; CI must prove the intended false-versus-true failure before
implementation. Production composition is unchanged and still rejects packs.
The vector tests primitive verification, not canonical release composition;
tampering, wrong keys, revocation and composed installation remain pending.

## Ed25519 verified red and candidate — 26 October 2026

CI `40347909282` on `11ed5b33` proves intended red: expected true,
actual false for the published public verification vector. Formatting,
analysis, browser/content, secrets and historical replay pass.
Implemented public verification using the existing cryptography dependency:
resolve a uniquely trusted key, construct its Ed25519 public key and verify
the supplied payload/signature. Consulted the package's official Ed25519 API
documentation. No private key or signing operation was introduced.
Permanent replay retains the red head. Full CI is pending. Malformed signature
handling, tampering/revocation negative coverage and production composition
remain separate acceptance work; this is not a complete security claim.

## Ed25519 behavioural green and formatting diagnosis — 26 October 2026

CI `40358213474` passes the native test step, including the public Ed25519
verification vector, and permanent red replay. Its sole failed step is
formatting; subsequent analysis, content/browser and coverage enforcement are
skipped, so no full-green claim is made.
Added a non-mutating exact formatter-output diagnostic for the production
Ed25519 verifier before the unchanged fatal formatter. Retrieve canonical
output, apply it exactly, and remove the diagnostic before authoritative CI.
No assertions or security behaviour were changed in this diagnosis.

## Exact Ed25519 formatting recovery — 26 October 2026

Diagnostic CI `40366661475` passes native tests, secret scanning and red
replays, but fails formatting; later gates remain skipped. Applied exact
timestamp-stripped canonical verifier source and removed the temporary
diagnostic without changing behaviour or assertions. Fatal formatting remains
unchanged. Replacement full CI is pending; no full-green claim is made.

## Ed25519 full green and malformed signature red contract — 26 October 2026

Exact-head full CI `40376846809` passes on `19f03815`.
Added the next negative boundary: empty, short and long signatures for a trusted
public key must return false without throwing. No production validation change
is present. CI must establish whether the dependency throws for the malformed
lengths before the corresponding defensive fix; no observed red is claimed yet.
No signing operation or private key was introduced. Tampering, revocation,
ambiguity and production-composed installation coverage remain outstanding.

## Malformed signature verified red and fix — 26 October 2026

CI `40387010184` on `43ea5a5b` proves intended red: Invalid argument
(signature): Invalid signature length. Formatting, analysis, browser/content,
secrets and prior replay gates pass. Added a 64-byte signature length guard
before trust resolution/crypto verification so malformed lengths return false.
Retained the exact red head in permanent replay; no assertions were weakened.
Replacement full CI is pending. Invalid byte values, tampering, wrong-key,
revocation/ambiguity and production composition coverage remain outstanding.

## Signature length green and negative characterization — 26 October 2026

Exact-head full CI `40394152485` passes on `681b7071`.
Added characterization coverage for the existing verifier's denial of an
unknown key, a tampered payload, an altered signature and an otherwise valid
signature after local revocation. Reuses only the published RFC public vector.
No production code changed and no failure was manufactured; this is existing
behaviour characterization under AGENTS.md. CI must verify these negative
examples. Invalid byte values, wrong-key/ambiguity coverage and production
composition remain pending; PR28 stays draft.

## Negative verification green and byte-range contract — 26 October 2026

Exact-head full CI `40401660375` passes on `1d9687a4`, including unknown
keys, payload/signature tampering and revoked-key denial.
Added a boundary test requiring 64-element signatures containing -1 or 256 to
return false without throwing. Production code is unchanged. CI must establish
whether the existing dependency already satisfies this contract; if it passes,
record characterization rather than manufacture a red. A defensive production
change requires observed intended red first.
Wrong-key/ambiguity verification and production composition remain outstanding.

## Byte-range characterization and key mismatch coverage — 26 October 2026

Full CI `40413270015` passes on `7c370287`: the existing dependency already
denies the tested -1/256 signature values without throwing. Recorded this as
characterization; no production guard or manufactured red was introduced.
Added existing-behaviour coverage that a different RFC public key cannot verify
TEST 1's signature, and that two publishers claiming the same key ID cannot
verify even with matching public bytes. Uses only previously consulted RFC
public material. No production code changed; replacement CI is pending.
Production composition, operator controls and independent review remain open.

## Wrong-key behavioural green and formatting diagnosis — 27 October 2026

CI `40421964326` passes native tests, including wrong-key and ambiguous
publisher denial. Formatting is the only failed step; later gates are skipped.
Added a non-mutating canonical formatter-output diagnostic for the verifier
test before the unchanged fatal gate. No full-green claim is made.
Also located the production native lifecycle opener's unconfigured verifier;
do not replace it until a production-composed test establishes the next red.
No production behaviour changed in this diagnosis.

## Negative verification exact formatting recovery — 27 October 2026

Diagnostic CI `40424789390` passes native tests, secrets and retained red
replay. Applied its exact timestamp-stripped canonical verifier-test output,
without assertion changes, and removed the diagnostic. The fatal formatter
remains unchanged. Replacement full CI is pending; later gate success is not
claimed from the diagnostic run. Production composition remains unchanged.

## Native composition test-first boundary — 27 October 2026

Recovered unchanged `24b9f473`, fully green in CI `40433331574`.
Extracted the native opener's existing reject-all verifier selection into a
public composition function accepting its SQLite database. The opener now calls
that function, which still returns the same reject-all verifier: no passing
trust behaviour was added. Added a business test enrolling the public RFC key
then requiring the exact native factory to verify its public vector.
CI must establish intended false-versus-true red before wiring the real
verifier. This tests the native verifier composition boundary, not yet a full
signed-release installation journey or operator onboarding UI. No private
signing material, release or merge is involved.

## Native composition verified red and candidate — 27 October 2026

CI `40442798652` on `fe718fe7` proves intended composition red: expected
true, actual false from the native factory. It also reports native-opener
formatting drift. Wired that factory to Ed25519ContentPackSignatureVerifier
with SqlitePublisherTrustStore on the same lifecycle database; removed the
obsolete reject-all implementation. Empty/unknown trust still denies via the
real verifier. Retained red replay and added a non-mutating exact-format
diagnostic for the native opener before the unchanged fatal gate.
Replacement full CI is pending. Full signed-release installation and explicit
operator controls are not established by this factory-level test.

## Native composition formatting recovery — 27 October 2026

Diagnostic CI `40446846767` passes native tests, including the real native
factory/public-vector test, secret scanning and retained red replay. Formatting
is its sole failure; subsequent gates remain skipped. Applied the exact
timestamp-stripped canonical native opener output and removed its diagnostic.
No behaviour or assertions changed; fatal formatting remains unchanged.
Replacement full CI is pending. Full installation journey and operator controls
remain outstanding; this is not final review readiness.

## Native composition analysis correction — 27 October 2026

CI `40455394983` passes formatting, native tests, secrets and retained red
replay. Static analysis fails only directives_ordering in the verifier test:
the new native-opener import follows sqlite_publisher_trust_store rather than
alphabetical order. Sorted package imports without assertion or behaviour
changes. Content/browser and coverage enforcement were skipped in that run.
Replacement full CI is pending. No review discussion is present and PR28
remains draft; full installation/operator acceptance is still incomplete.

## Native signature trust full green — 27 October 2026

Exact-head full CI `40458220054` passes on `35343e33`.
Reconciled the slice and threat-model draft's stale unconfigured-verifier claims
with the delivered unique resolution, Ed25519 negative cases and native factory
composition. Explicitly retained full installation, operator, race/failure,
dependency/coverage and independent-review gaps. No feature checkbox was marked
complete. Records-only change; no production code or assertions changed.

## Native verification restart characterization — 27 October 2026

Recovered unchanged head `9f6e05fd`, full CI `40468000052` passing.
Added existing-behaviour integration characterization through the exact native
verifier factory: enroll into a real file, close/reopen and verify the public
RFC vector, revoke, close/reopen again and require denial. Isolated temporary
storage is removed after closing connections. No signing material or production
change is introduced; no red is manufactured. CI verification is pending.
This extends factory/storage evidence but is not full canonical-release
installation coverage or operator UI acceptance.

## Native restart behavioural green and formatting diagnosis — 27 October 2026

CI `40473095811` passes native tests including trust/revocation verification
across actual close/reopen cycles. Formatting of the verifier test is the sole
failed step; later analysis/content/browser/coverage gates are skipped.
Published the non-mutating exact formatter-output diagnostic before the
unchanged fatal gate. Apply canonical output and remove diagnostic before
claiming full green. No production code or assertions changed.

## Native restart exact formatting recovery — 27 October 2026

Diagnostic CI `40482765998` passes native tests, secrets and retained red
replay. Applied its exact timestamp-stripped verifier-test source, including
the multiline restart test declaration; no assertions changed. Removed the
diagnostic and retained the fatal formatting gate. Later gates were skipped
in the diagnostic run; replacement full CI is pending.

## Restart full green and installation denial coverage — 27 October 2026

Full CI `40487967150` passes on `008e82a4`, including native verification
across trust/revocation restarts. Added existing-behaviour integration coverage
using the native verifier factory in the real SQLite installer composition:
an unsigned/untrusted release must fail verification, leave no active version,
and retain bundled fallback on startup. No production behaviour changed and
no red was manufactured. CI must verify this characterization.
This covers the fail-closed installation journey, not a successful signed
canonical-release installation. Operator controls/review remain outstanding.

## Installation denial behavioural green and formatting diagnosis — 27 October 2026

Recovered unchanged head `49ec053a`; PR28 has no review discussion or active-work
marker. CI `40495183637` passes native tests, including the native-composed
untrusted installation denial, unchanged activation and bundled fallback
characterization. Secret scanning and retained red replay also pass. Formatting
of content_pack_lifecycle_composition_test.dart is the sole failed step;
analysis, content/browser and coverage enforcement are skipped, so full green
is not claimed. Added a non-mutating exact formatter-output diagnostic before
the unchanged fatal formatting gate. Apply CI's canonical output and remove
that diagnostic before authoritative replacement CI. No production behaviour,
assertion or feature-completion status changed. Full signed-release installation,
operator controls and explicit independent review remain outstanding.

## Installation denial exact formatting recovery — 27 October 2026

Diagnostic CI `40504318677` passes native tests, secret scanning and retained
red replay. Formatting remains the sole failed step; later gates are skipped.
Applied its exact timestamp-stripped canonical lifecycle-composition test
source and removed the temporary diagnostic. Assertions and production behaviour
are unchanged; fatal formatting remains intact. Recovered unchanged PR28 head
`92651e13` before edits. Replacement full CI is pending; successful signed-release
installation, operator controls and independent review remain outstanding.

## Installation denial full green and review checkpoint reconciliation — 27 October 2026

Exact-head full CI `40509261693` passes on `e8aa40ba`: native-composed
untrusted installation denial, unchanged active version and bundled fallback
are verified alongside restart and cryptographic negative coverage. Recovered
unchanged head and empty review discussion. Reconciled the stale PR summary
with delivered Ed25519 verification and native composition, while explicitly
retaining successful canonical-release installation, operator controls,
concurrency/failure evidence, dependency/coverage reconciliation and independent
review as open acceptance work. No feature completion or review readiness is
claimed; no production code or tests changed in this records checkpoint.

## Stored publisher identity red contract — 27 October 2026

Recovered unchanged PR28 head `72e0103c`. Inspection finds that key-only
resolution casts the stored publisher identity directly to String. SQLite's
non-strict TEXT column can contain a BLOB, unlike the normal enrollment path.
Added a safety test requiring malformed stored publisher identity to resolve
as untrusted without throwing. This complements existing stored-key corruption
coverage; it does not claim protection against an attacker controlling storage.
No production fix is present. CI must prove the intended cast failure before
any defensive change; no observed red is claimed yet. Full installation and
operator acceptance remain outstanding.

## Stored publisher identity verified red and fix — 27 October 2026

CI `40530782214` on `415b474e` proves intended red: malformed stored publisher
identity throws type 'Uint8List' is not a subtype of type 'String' in type cast.
Formatting, analysis, content/browser, secrets and historical replay pass.
Added only a stored-type check returning null before delegation to trusted pair
lookup. No assertion changed; normal enrolled identities retain their behaviour.
Permanent replay retains the exact test-first head. Replacement full CI is
pending. This is defensive corruption handling, not resistance to device control
or simultaneous concurrency evidence. PR28 remains draft.

## Publisher identity behavioural green and formatting diagnosis — 27 October 2026

Recovered unchanged head `a35e26ef`. CI `40539444469` passes native tests,
including malformed publisher identity denial, retained red replay and secrets.
Formatting is the sole failed step; subsequent gates are skipped. Published
non-mutating exact formatter output for the trust-store implementation before
the unchanged fatal gate. No assertions or business behaviour changed. Apply
canonical output and remove diagnostic before authoritative full CI. Operator
controls and the other recorded acceptance gaps remain open.

## Stored identity exact formatting recovery — 27 October 2026

Diagnostic CI `40549709646` passes native tests, secrets and retained red
replay; formatting is the sole failure and later gates are skipped. Recovered
unchanged head `8cf8099a`. Applied exact timestamp-stripped canonical trust-store
source and removed the temporary diagnostic, retaining the fatal gate.
No assertions or production behaviour changed. Replacement full CI is pending;
remaining operator, installation and independent-review acceptance stays open.

## Stored identity full green and unfinished transaction coverage — 27 October 2026

Recovered unchanged `9446fd75`; full CI `40562481843` passes, including the
malformed stored publisher identity fix and its retained red replay.
Added existing-behaviour characterization for closing a database with an
unfinished trust transaction: after reopening, prior committed trust remains
and neither uncommitted revocation nor new-key enrollment survives. This
complements explicit ROLLBACK coverage but is not a process-kill, power-loss,
disk-failure or simultaneous race simulation. No production behaviour changed
and no red was manufactured. CI must verify the new characterization. Remaining
operator controls, successful signed installation and independent review stay open.

## Unfinished transaction full green and acceptance reconciliation — 27 October 2026

Exact-head full CI `40572197316` passes on unchanged `c214b268`. Reconciled
the operational-security acceptance checkpoint with verified fail-closed install,
malformed stored identity handling and unfinished transaction close/reopen
characterization. Explicitly retained successful canonical-release installation,
operator controls, simultaneous concurrency/failure limitations, dependency and
coverage assessment and independent review. No production code, assertions or
feature completion status changed. PR28 remains draft.

## Pre-enrollment revocation characterization — 27 October 2026

Recovered unchanged `4428298d`; full CI `40587996345` passes. Added existing-
behaviour coverage for an operator revoking a not-yet-enrolled identity twice,
closing/reopening SQLite, then attempting enrollment. The tombstone must remain
binding, enrollment must throw StateError, and key-only resolution must remain
untrusted. This tests idempotent offline revocation distribution arriving before
a public key; no production change or manufactured red is introduced. CI is
pending. This is not the unfinished operator interface or full signed install;
those acceptance gaps and independent review remain open.

## Pre-enrollment revocation full green and operator boundary selection — 27 October 2026

Recovered unchanged `e3196ee1`; exact-head full CI `40594970273` passes,
including duplicate pre-enrollment revocation and restart denial. No review
comments are present. Selected the next missing acceptance boundary: an explicit
confirmed local operator application service over durable trust, separate from
pack metadata/install admission. Published bounded acceptance criteria for
unconfirmed denial, confirmed enrollment, rotation and revocation without
claiming that service or its user-facing composition exists yet. Records-only
change; no production behaviour, tests or completion checkboxes changed.

## Operator confirmation red boundary — 28 October 2026

Recovered unchanged `efc52aaa`. Published a test requiring unconfirmed operator
admission to throw StateError and leave key resolution untrusted. Added only
the minimum compiling application-adapter seam, throwing UnimplementedError;
it does not implement confirmation or durable enrollment. CI must establish
intended missing-policy red before implementation. This is a local service
boundary, not completed UI/CLI composition. No private signing material or
feature completion claim is included.

## Operator confirmation verified red and denial — 28 October 2026

CI `40606302196` on `de389cbd` proves intended red: the operator admission
test receives UnimplementedError instead of the required StateError. Formatting,
analysis, content/browser, secrets and historical replay pass. Implemented only
the refusal contract using StateError without touching durable trust. Confirmed
admission is deliberately not implemented until its next positive red example;
no implied completion of operator controls. Retained exact red replay. Full CI
is pending. No private material, merge or release is included.

## Confirmed operator admission red contract — 28 October 2026

Recovered unchanged `3dbd38c1`; exact-head full CI `40613697549` passes for
unconfirmed refusal. Added the next positive business example: explicit confirmed
admission must make the exact publisher/key bytes trusted without granting trust
to another publisher. The current service still always throws StateError; no
passing confirmed-admission implementation is included. CI must establish the
intended red before delegation to the existing durable enrollment policy.
No private signing material, UI completion or feature completion is claimed.

## Confirmed admission verified red and candidate — 28 October 2026

CI `40619959442` on `4bbadb6b` proves intended red: confirmed admission
throws Explicit operator confirmation is required. Formatting, analysis,
content/browser, secrets and prior replay pass. Added the confirmation guard
and delegated confirmed input to existing durable enrollment policy. Unconfirmed
admission still throws without mutation. Retained exact red replay. Full CI
is pending. Operator revocation, composition/UI and other acceptance gaps remain
open; this is not feature completion or independent review readiness.

## Confirmed admission full green and conflict characterization — 28 October 2026

Recovered unchanged `5d8bade3`; exact-head full CI `40627149483` passes.
Added existing-behaviour characterization through the operator boundary:
confirmed identical enrollment can repeat, conflicting public bytes throw,
and the original trust remains unchanged. No production behaviour changed or
red was manufactured. CI is pending. Operator revocation, durable service
restart coverage and user-facing composition remain incomplete along with
other recorded signed-installation/security acceptance work.

## Operator conflict behavioural green and formatting diagnosis — 28 October 2026

Recovered unchanged `1dfa21e4`. CI `40632782476` passes native tests,
including confirmed duplicate/conflict preservation, secret scanning and red
replay. Formatting is the sole failed step; later gates are skipped. Published
non-mutating exact formatter output for the operator test before the unchanged
fatal gate. No assertions or business behaviour changed; authoritative full CI
remains pending. Operator revocation and user-facing composition stay open.

## Operator conflict exact formatting recovery — 28 October 2026

Diagnostic CI `40636202091` passes native tests, secrets and retained red
replay. Formatting remains its sole failure; later gates are skipped. Recovered
unchanged head `831d8592`. Applied exact timestamp-stripped canonical operator
test output and removed the temporary diagnostic; fatal formatting remains.
No assertions or production behaviour changed. Replacement full CI is pending.
Operator revocation and other recorded acceptance gaps remain open.

## Operator revocation confirmation red boundary — 28 October 2026

Recovered unchanged `f86642bb`; full CI `40640197308` passes including
operator duplicate/conflict characterization. Added the next business example:
unconfirmed revocation must throw StateError while preserving enrolled trust.
Only a minimum revocation seam throwing UnimplementedError accompanies the test;
no passing refusal or revocation behaviour is implemented. CI must establish
intended missing-policy red before implementation. Confirmed revocation and
user-facing composition remain separate acceptance work. No feature completion
or independent-review readiness is claimed.

## Revocation confirmation verified red and refusal — 28 October 2026

CI `40646125024` on `61be61bd` proves intended red: unconfirmed operator
revocation throws UnimplementedError rather than StateError. Formatting also
flags the missing blank line before the new method; corrected that layout.
Implemented only StateError refusal without durable mutation. Confirmed
revocation deliberately remains unsupported until its positive red example.
Retained exact red replay. Full CI is pending; later gates were skipped in
the red run. No feature completion or independent review is claimed.

## Confirmed operator revocation red contract — 28 October 2026

Recovered unchanged `c888a71d`; full CI `40652615765` passes for refusal
without trust mutation. Added the next positive example: confirmed revocation
must remove key resolution and make subsequent confirmed re-admission fail.
Current service still refuses all revocation; no passing implementation is
included. CI must prove intended red before durable delegation. Restart,
rotation and user-facing composition remain separate acceptance evidence.
No private signing material or feature completion is claimed.

## Confirmed revocation verified red and candidate — 28 October 2026

CI `40660101502` on `4c726755` proves intended red: confirmed operator
revocation throws Explicit operator confirmation is required. Formatting,
analysis, content/browser, secrets and prior replay pass. Added confirmation
guard and delegation to existing durable revocation; unconfirmed requests still
refuse without mutation. Retained exact red replay. Full CI is pending.
Service restart/rotation coverage and user-facing controls remain outstanding;
no completion or independent-review readiness is claimed.

## Confirmed revocation full green and operator rotation coverage — 28 October 2026

Recovered unchanged `f9d88c1f`; exact-head full CI `40670987542` passes
including confirmed revocation and irreversible re-admission denial. Added
existing-behaviour characterization through the operator service: admitting a
new key preserves both keys until explicit confirmed revocation of the old key,
which must not revoke the new key. No production behaviour changed and no red
was manufactured. CI is pending. Service restart, user-facing composition and
remaining signed-install/security acceptance gaps stay open; PR28 remains draft.

## Operator rotation full green and restart characterization — 28 October 2026

Recovered unchanged `2e9c336f`; full CI `40679250833` passes including
operator rotation without silent revocation. Added existing-behaviour coverage
through the service on a real database file: admit old/new keys, revoke old,
close/reopen, preserve new trust and reject old-key re-admission. No production
change or manufactured red is present. CI is pending. This is service durability,
not yet user-facing composition, simultaneous concurrency or full signed-release
installation. All remaining acceptance and review gaps stay open.

## Operator restart full green and checkpoint reconciliation — 28 October 2026

Recovered unchanged `76c81778`; exact-head full CI `40682860127` passes.
Reconciled the slice with delivered confirmation guards, durable admission and
revocation, duplicate/conflict, rotation and restart service coverage. Explicitly
retained missing operator UI/CLI composition and instructions, successful signed
canonical-release install, concurrency/failure hardening, dependency/coverage
assessment and independent review. Records-only change; no assertions, production
behaviour or completion checkboxes changed. PR28 remains draft.

## Operator command confirmation red boundary — 28 October 2026

Recovered unchanged `29e4af53`. Added a command-boundary test: enrollment without
explicit confirmation must return nonzero and leave durable trust empty. Only a
minimum adapter throwing UnimplementedError accompanies it; CI must establish
intended red before implementation. Bounded intended grammar: enroll publisherId
keyId publicHex --confirm, or revoke publisherId keyId --confirm. A subsequent
executable must require an explicit existing database path, never guess/create an
application database. No executable, passing parser, signing material or completion
claim is included. An initial orchestration syntax error made no repository calls;
corrected the orchestration and published this test-first checkpoint.

## Command refusal verified red and candidate — 28 October 2026

CI `40706537422` on `b86f1e35` proves intended red: unconfirmed command
throws SP-006 trust command is not implemented instead of returning nonzero.
Formatting also fails. Implemented only usage/refusal status 64 without durable
mutation; confirmed command admission is deliberately unsupported pending its
positive test. Retained exact red replay and added non-mutating canonical
formatter output for the command adapter before the unchanged fatal gate.
Full CI is pending. No executable or completed operator interface is claimed.

## Command refusal formatting recovery — 28 October 2026

Recovered unchanged `4cbda444`. The prior diagnostic was initially aimed at
the adapter; corrected it to the test actually reported by the formatter before
this run. Diagnostic CI `40711309464` passes native tests, secrets and retained
red replay; formatting alone fails and later gates are skipped. Applied exact
timestamp-stripped canonical command-test source, removed the diagnostic and
retained fatal formatting. No assertions or behaviour changed. Replacement
full CI is pending; confirmed commands and executable remain unimplemented.

## Confirmed enrollment command red contract — 28 October 2026

Recovered unchanged `8dd4e717`; full CI `40724793440` passes command refusal.
Added a positive test for the bounded enroll publisherId keyId publicHex
--confirm grammar: return zero and persist exact decoded public bytes. Current
adapter still returns usage status 64 for every request. No passing parser or
admission implementation accompanies this test. CI must establish intended red
before implementation. Malformed/unknown commands, revocation command and the
explicit-database executable remain subsequent bounded acceptance work.

## Confirmed enrollment command verified red and candidate — 28 October 2026

CI `40738290832` on `2cef66bf` proves intended red: expected zero, actual 64
for confirmed enrollment. Test formatting also fails; later gates are skipped.
Implemented exact five-argument enrollment grammar with --confirm, bounded
64-character hex decoding, and delegation to the confirmed operator policy.
Other forms remain refused. Retained exact red replay and added non-mutating
canonical formatter output for both adapter/test before unchanged fatal gate.
Full CI pending. Malformed/error characterization, revocation grammar and the
explicit-existing-database executable remain outstanding.

## Command compilation correction — 28 October 2026

CI `40743319559` fails formatting and native loading: JavaScript replacement
suffix expansion corrupted the anchored hex regex raw string. Inspected durable
source and restored the intended 64-hex pattern using literal callback replacement.
No assertions or intended policy changed. Retain formatting diagnostic because
invalid source prevented canonical output. No behavioural/full green is claimed;
secrets and retained red replay pass. An orchestration syntax error made no calls
before the corrected update. Replacement CI remains pending.

## Confirmed command behavioural green and formatting recovery — 28 October 2026

Recovered unchanged `db0a8871`. CI `40756919774` passes native tests,
including confirmed command enrollment, secrets and retained red replay.
Formatting alone fails; later gates are skipped. Applied exact timestamp-stripped
canonical adapter/test outputs and removed temporary diagnostic, preserving the
fatal gate. No assertions or intended behaviour changed. Replacement full CI is
pending; malformed/error coverage, revoke command and executable remain open.

## Confirmed command full green and malformed input characterization — 28 October 2026

Recovered unchanged `ce031191`. CI `40765252840` was cancelled during native
tests after earlier gates passed; reran only the cancelled build/test job.
The completed retry now passes full CI. Added existing-behaviour coverage for
empty/unknown commands, short/non-hex keys, wrong confirmation and excess args:
nonzero status and no admitted trust. No production change or manufactured red
is present. CI pending. Revoke grammar, policy-error handling and explicit-path
executable remain unfinished along with remaining security acceptance/review.

## Malformed command CI diagnosis — 28 October 2026

Recovered unchanged `9d68dad5`. CI `40782553025` reports formatting failure
before cancellation during native tests. Secret scanning and retained red replay
pass. Native characterization success is not established; later gates are skipped.
Published non-mutating canonical output for the changed command test before the
unchanged fatal formatting gate. Do not rerun the known formatting failure
unchanged. No assertions or business behaviour changed; full CI remains pending.
