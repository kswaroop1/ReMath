# PR22 — Portable backup and recovery

## User — 20 September 2026

> Merged. Go to next feature set as planned.

## Assistant — selection

The repository and prior agreed infrastructure sequence were reconciled after
PR21 merged. PR22 is the portable backup/recovery slice, followed by content-pack
lifecycle and operational security. The accepted working rules continue:
test-first red/green commits, meaningful coverage near 100%, chronological AI
provenance, green CI, explicit independent `@codex review`, and correction of
review findings before handoff. Merge control remains with the user.

Selected DS-004, DS-016, DS-017, SP-005 and SP-012 foundations. The slice uses
encrypted versioned export, read-only preview, transactional idempotent event
merge and a provider-neutral file boundary. It excludes cloud sync, OAuth,
content-pack transfer, release and VERSION changes.

## Cycle 1 select/red — portable payload

Acceptance: a version-one payload reproduces every immutable attempt field,
orders events canonically, normalizes persisted times to UTC, preserves Unicode
answers and the optional study snapshot, and re-encodes identically. Unsupported
versions, duplicate event IDs and invalid negative response times fail before
any import can occur.

The red commit adds only behavior tests importing the required public payload
seam. The expected red failure is the missing
`features/backup/domain/backup_payload.dart` library; no production behavior is
included in that commit.

CI run 35499113853 failed at the intended missing-library boundary:

```text
Error when reading 'lib/src/features/backup/domain/backup_payload.dart':
No such file or directory
```

The same run also identified canonical formatter changes required in the test.
The green implementation adds only the package-neutral payload codec and its
validation; it adds no encryption, file or import behavior prematurely.

CI run 35499557610 verified the payload implementation.

## Cycle 2 red/green — authenticated encryption

The red contract required password-derived authenticated encryption, no
plaintext leakage, wrong-password and tamper rejection, strict envelope
validation, and injectable salt and nonce sources for deterministic tests. CI
run 35503629845 recorded the expected missing implementation. The green change
used Argon2id and AES-256-GCM, authenticated the security metadata, and committed
the dependency lock. CI run 35515361087 verified the implementation after the
CI-generated transitive lock entry and canonical formatting were reconciled.

## Cycle 3 red/green — read-only import preview

The red contract required a complete decrypt-and-validate pass that writes no
data and reports payload version and creation time, new/duplicate/conflicting
attempt counts, skill and time ranges, and snapshot presence. Conflicting event
IDs must make the preview inapplicable. CI run 35519550576 recorded the expected
red boundary; CI run 35519706225 verified the minimal preview implementation.

## Cycle 4 red/green — transactional recovery

The red contract required idempotent immutable-event union, conflict rejection,
atomic SQLite application, and protection for an existing active study. CI run
35523312758 recorded the expected red behavior. The repository implementations
then applied new events and an eligible snapshot in one transaction, with
equivalent events ignored and any validation or write failure rolling back. CI
run 35525416061 verified the behavior.

## Cycle 5 red/green — application coordinator

The red coordinator contract separated export, preview, and explicit apply,
and rejected unsafe imported snapshot JSON before any write. CI run 35525883597
recorded the red boundary. The implementation composed the codec, cipher and
repository while retaining a validated pending import between preview and
apply. Compatibility and fail-closed error normalization corrections followed;
CI run 35531506867 verified the final coordinator.

## Cycle 6 red/green — provider-neutral file transfer

The red file-boundary contract required a stable `.remath-backup` export name,
safe cancellation, a read-only preview, and explicit application without
leaking provider concerns into the domain or coordinator. CI run 35536035961
recorded the expected red boundary. CI run 35536206303 verified the boundary and
transfer implementation.

## Cycle 7 red/green — learner-facing recovery journey

The widget red contract required matching password confirmation, visible export
success, preview counts without writes, an explicit Apply backup action, and a
visible restored-attempt result. CI run 35537564109 recorded the expected red
boundary. The implementation added the backup-and-recovery screen and isolated
expensive production Argon2 work from widget tests through the existing cipher
seam. CI run 35544999179 verified the journey.

## Cycle 8 red/green — production file selection and navigation

The red integration contract required Home navigation, production coordinator
composition, user-selected open/save handling, safe cancellation, and the
minimum macOS entitlement. CI run 35547974161 recorded the expected red
boundary. The green implementation added a `file_picker` data-layer adapter,
application wiring, and the user-selected-file entitlement. The dependency
lock was regenerated through CI and committed. CI run 35548530327 verified 314
tests at 98.34 percent line coverage, formatting, analysis, content validation,
Chrome contracts, and secret scanning.

The dependency decision records `file_picker` 13.1.0 as actively maintained,
MIT licensed, and able to provide open and save selection across the supported
platforms. It receives encrypted bytes only, no password or derived key, and no
network or telemetry permission. `file_selector` was rejected because its save
journey is unavailable on Android, iOS, and web.

## Cycle 9 red/green — password recovery warning

The acceptance register requires an explicit warning because encrypted backups
cannot be recovered after a password is forgotten. CI run 35551231469 recorded
the focused widget test failing before implementation. The separate green
commit added the visible warning next to the password controls; CI run
35551472718 verifies that final behavior.

## Independent review and correction cycles

Independent `@codex review` at head `9cf2b76` found ten substantive issues.
All findings were accepted: stale pending imports after a failed preview,
incomplete preview metadata, response-time precision loss, missing rollback
evidence, inactive study rows blocking recovery, stale cached Home state,
misleading web availability, missing Chrome coverage, omitted active learning
sessions and an incomplete cryptography dependency assessment.

The first correction red run 35554216125 required failed previews to invalidate
the previous pending import, complete learner-visible preview metadata and
microsecond response precision. The implementation was verified while a widget
harness correction was identified in run 35558151778.

Those three independent behaviors were batched in one red commit and one green
commit. That history does not satisfy the repository's preferred one-cycle-per-
behavior discipline and cannot be reconstructed honestly after the fact. The
review finding is therefore retained as an explicit process deviation rather
than described as three separate compliant cycles.

Run 35561097077 recorded the rollback and inactive-study-state red boundary.
Run 35561462113 verified simulated interrupted-write rollback and restoration of
a genuinely active imported snapshot when the local row is inactive. Run
35563686217 recorded the cached-state red boundary; after compatibility and
assertion corrections, run 35568242006 verified that Home reloads persisted
state after recovery.

Run 35568583495 recorded the web platform-boundary red result. After canonical
Dart 3.13 formatting corrections, run 35589340047 verified in Chrome that
backup/recovery is omitted on web until progress storage is durable while native
platforms retain the file-picker journey.

Run 35592039942 recorded the missing active-session behavior. The green change
added complete session payload encoding and protected, transactional repository
merge semantics. Runs 35601541171 and 35605045558 exposed test-double,
formatting and analysis integration corrections; run 35613006975 verified the
final behavior with 321 native tests plus the Chrome contract suite.

The dependency assessment now records `cryptography` 2.7.0 specifically:
Apache 2.0 licensing, maintained cross-platform upstream, pure-Dart use behind
`BackupCipher`, no network or telemetry surface, deterministic randomness only
through tests, and a separate review requirement for future upgrades.

Independent re-review at head `5574aac` found seven further issues. The
accelerated correction stack kept focused red and green commits while publishing
related corrections together rather than waiting for CI after every local
commit. Runs 35640719926 and 35644110210 recorded and verified fail-closed
validation of incoherent Learn sessions. Runs 35651856239 and 35653833728
recorded and verified that inactive study rows are not advertised as resumable.
The same stack separately disclosed active Home sessions in preview, added
focused SQLite restoration, local-protection and rollback characterization, and
corrected the review-exchange and TDD-batching record. Run 35656033821 verified
that combined stack.

Run 35663086168 recorded the final expected red boundary: an exported learning
session did not retain the generated question ID and skill. The green change
now carries both fields through the canonical payload, schema-eight SQLite
persistence and controller restoration. The question ID pins pack, template,
template version, seed and index; the skill pins the exact operation selected
for a mixed Home session. Restoration fails closed if regenerated identity does
not match. CI run 36234712494 exposed only Dart 3.13 formatting and idempotent
migration-fixture corrections after 323 tests passed. Run 36234982471 verified
the final result: 327 native tests, eight Chrome tests, 98.36 percent line
coverage, formatting, static analysis, content validation and secret scanning.

## Final review corrections and coverage accounting

Independent review at head `dfb31ca` identified two related restored-session
identity failures and asked for an exact explanation of the coverage change
from PR21. Commit `34e50fa` specified the coordinator rejection seam and the
pre-edit identity requirement, but it did not specify the production content-
pack compatibility policy. That policy and its direct unit coverage landed
together in `730e78e`; this was a production-first deviation, not a complete
test-first cycle. The implementation pins identity on every persisted question
transition and validates imported pack, template version, seed, index and
operation against installed content. CI run 36245395349 verified 331 native
tests and the Chrome contracts after one formatter-only correction.

Coverage was then treated as characterization rather than manufactured red
behavior. Tests were added for duplicate incoming IDs in both repositories,
immutable-conflict reporting, refusal to apply a conflicting preview,
decryption-error presentation, and malformed injected entropy. CI runs
36248148245, 36248363204, 36250762320, 36250934137 and 36255743946 exposed one
test-harness error and canonical Dart formatting differences while all behavior
tests passed. The low-value combinatorial payload matrix was removed rather
than retaining formatter churn; the existing payload suite still covers
canonical round trip, version rejection, duplicate and invalid events,
incoherent sessions and exact identity. CI run 36255837351 is the final green
result: 334 native tests, eight Chrome tests and 98.47 percent line coverage.

PR21's 98.99 percent baseline already left isolated number curriculum, study
plan, study controller/screen and schema-seven rollback lines uncovered. PR22
does not claim those pre-existing paths as a backup regression. The remaining
PR22-only uncovered lines are deliberately bounded: the real OS file-picker
gateway, production secure-random generator, production composition callback,
defensive missing-template catch, schema-eight migration rollback, and
redundant malformed-payload sub-branches. Their policies are exercised through
injected file, entropy, coordinator, compatibility, repository-transaction and
payload seams. Direct execution would either duplicate those contracts or
invoke host OS/plugin and nondeterministic entropy boundaries. The PR therefore
improves the reviewed 98.36 percent result to 98.47 percent and documents the
remaining delta instead of adding assertion-free line execution.

## Legacy-session and payload-contract review corrections

Independent review at head `a6a2e75` found that a legacy Learn session could
name a removed concept, that an unpinned legacy session could be exported and
restored against a different question, and that malformed-payload assertions
had been removed during formatter cleanup. It also identified the inaccurate
test-first claim for `34e50fa` and `730e78e` corrected above.

The focused red commit `b17a0e2` requires removed Learn concepts to fail closed
and legacy non-Learn sessions to acquire their exact generated-question
identity during controller initialization. The green commit `e4672ba` validates
the Learn focus against the installed content pack and persists identity for an
otherwise unpinned restored question. Commit `aefc4e5` restores explicit tests
for non-object payloads, timezone-free timestamps, non-list attempts,
non-string study state, unknown event kinds and non-boolean correctness. These
assertions use formatter-stable helpers; no behavioral contract was discarded
to satisfy formatting. CI run 36264353536 then exposed one missing required
fixture field and the canonical multiline test layout; all 334 other tests
passed. The fixture and formatting were corrected without changing production
behavior. CI run 36264737676 then verified the complete correction: 338 native
tests, eight Chrome contracts and 98.52 percent line coverage.

## Diagnostic-bound and SQLite-precision review corrections

Independent review at head `28098ac` found that an identity-less legacy
diagnostic could name an index beyond its fixed nine-question set, that SQLite
recovery truncated sub-millisecond response durations and broke retry
idempotency, and that the preceding green run had not yet been appended here.

Combined red commit `fc58642` specifies rejection of the unsafe diagnostic and
exact microsecond preservation across SQLite recovery and retry; combined green
commit `6a694f7` implements both behaviors. This batching is a TDD-process
deviation because the repository requires a separate red-green-refactor cycle
for each behavior. It is retained and disclosed rather than represented as a
compliant focused cycle. The implementation validates the diagnostic bound and
advances progress schema nine with a backfilled `response_us` column while
retaining the legacy millisecond column for migration compatibility. CI run
36271467222 is green: 340 native tests,
eight Chrome contracts, 98.50 percent line coverage, formatting, static
analysis, content validation, dependency-lock verification and secret scanning.

## Hint-bound and schema-nine evidence corrections

Independent review at head `abc3132` required explicit disclosure of the
combined cycle above, schema-nine rollback coverage, preview-time rejection of
hint counts beyond the four-level UI contract, and the durable schema-nine
architecture record. Hint validation has a distinct red/green history in
`a3539e1` and `b6fce62`. Commit `0309138` characterizes the already-implemented
schema-nine rollback path by forcing the backfill to abort and verifying that
both schema version eight and the absence of `response_us` are restored; it is
coverage added after production, not claimed as test-first. Commit `25b82fd`
records the version-nine persistence and compatibility contract. The coverage
change from 98.52 to 98.50 percent was the newly added migration branch; after
its interruption test, CI run 36276714619 reports 342 native tests, eight Chrome
contracts and 98.53 percent line coverage with every gate green.

## Material review exchange

The exact first-review findings and repository responses remain available in
the pull-request threads: [stale preview][r1], [cryptography assessment][r2],
[rollback evidence][r3], [inactive study state][r4], [cached Home state][r5],
[preview metadata][r6], [web durability][r7], [response precision][r8],
[browser evidence][r9], and [active Home session][r10]. The re-review exchange
is likewise preserved verbatim: [session invariants][r11], [inactive preview
state][r12], [Home-session preview][r13], [review provenance][r14], [question
identity][r15], [TDD batching][r16], and [SQLite session recovery][r17].
The final legacy-session review is linked in full: [removed Learn concept][r18],
[unpinned legacy identity][r19], [payload assertions][r20], and [historical TDD
claim][r21].
The final precision review is linked in full: [diagnostic bound][r22],
[SQLite microseconds][r23], and [final green provenance][r24].
The last evidence review is linked in full: [batched TDD deviation][r25],
[schema-nine rollback][r26], [hint bound][r27], and [schema-nine architecture][r28].

CI run 36276949704 verified the evidence-only head `dafde6f` with every gate
green. Independent review of that head then identified three further behavioral
boundaries and the missing final run in metadata. The corrections retain a
separate local red/green commit pair for each behavior before publishing the
complete stack: remediation sessions must keep their focus skill consistent
with their pinned question identity; merely visiting backup/recovery must not
reset the active Home question timer; and inactive imported study rows must not
replace the user's local inactive goal choice. The exact review findings are
preserved as [final CI record][r29], [remediation focus][r30], [Home elapsed
time][r31], and [inactive imported study][r32].

CI run 36283613274 executed the complete correction stack. All 344 native tests
passed, including the three focused corrections; the only failure was Dart
3.13's canonical multiline layout for the inactive-import test. The subsequent
correction changes formatting and records only, not production behavior.

CI run 36283768966 is the clean full-suite result: formatting, static analysis,
content validation, dependency-lock verification, secret scanning, eight Chrome
contracts, 344 native tests and the 98.51 percent line-coverage gate all pass.

## Final focused-session and evidence corrections

Independent review at head `7ad238e` found two remaining compatibility gaps:
focused question/review sessions could disagree with their pinned skill, and a
pinned diagnostic could exceed its fixed nine-question set. Separate local test
and implementation commits were retained for each correction. As with the
preceding three local pairs, Flutter could not run in the local environment and
the stack was pushed together for permitted CI execution. There is therefore no
honest per-commit red or green execution evidence for these five cycles; the
commit ordering records intent and separation, while the combined CI runs are
the only execution evidence. This is an explicit TDD-process deviation.

The coverage movement from 98.53 percent at run 36276714619 to 98.51 percent at
run 36283768966 came from the new Home recovery callback/conditional refresh
composition path. The screen-level callback and cancellation path were covered,
but the successful apply-through-Home path was not. A focused characterization
test now performs preview, apply, back navigation and verifies refreshed Home
progress. This is coverage added after production, not claimed as test-first.
The exact findings are preserved as [missing cycle executions][r33], [coverage
accounting][r34], [all focused sessions][r35], and [pinned diagnostic bound][r36].

CI run 36285767915 verifies the combined correction: 347 native tests, eight
Chrome contracts and restored 98.53 percent line coverage, with formatting,
analysis, content, dependency-lock and secret-scanning gates all green.

Independent review of verified head `920db47` found four remaining restoration
invariants: remediation/review phases require a focus even when identity is
pinned; diagnostics require the operation assigned to their three-question
index block; active study requires a non-empty session ID; and an already
advanced local event stream must suppress an older active-study snapshot.
Each behavior has a separate ordered local test and implementation commit, but
the local environment still cannot execute Flutter. As disclosed above, the
stack is published together for CI and commit order is not claimed as red/green
execution evidence. The exact findings are [required focused-session focus][r37],
[diagnostic operation][r38], [active-study identity][r39], and [stale study
snapshot][r40].

CI run 36293085891 recorded the combined stack's first integration result:
the four focused invariants passed, but the suite exposed one legacy repository
fixture that supplied malformed placeholder study state, while Dart 3.13 also
reformatted three touched files. Commit `35f55ce` replaces that placeholder
with a real active `StudyState` and applies the corresponding formatting; its
run 36293321888 passed all 351 native tests but retained one callback-layout
formatting difference. Commits `b8d0741` and `7a8f585` replace the unstable
inline expression with a named event lookup. CI run 36293636129 is fully green:
351 native tests, eight Chrome contracts, 98.54 percent line coverage, and all
formatting, analysis, content, dependency-lock and secret-scanning gates pass.

Final-head CI run 36293824189 verifies documentation head `ee5e22c` with the
same 351 native tests, eight Chrome contracts and 98.54 percent line coverage;
all gates pass. Independent review of that head found that the compatibility
guard still accepted identity-less focused sessions before checking focus, and
that a successful review retest cleared the focus required by the guard. The
focused tests and implementations are preserved as separate ordered local
commits, then published together because local Flutter execution remains
unavailable; their ordering is not claimed as per-commit execution evidence.
The third finding was this missing final-head run itself. The exact findings are
[final-head provenance][r41], [review focus retention][r42], and [legacy focused
sessions][r43].

CI run 36297807270 verifies the complete correction stack at `3bb99cf`: 353
native tests, eight Chrome contracts and 98.54 percent line coverage pass,
together with formatting, static analysis, content validation, dependency-lock
verification and secret scanning. This run is the execution evidence for both
ordered test/implementation pairs described above.

Final-head CI run 36298024083 verifies reconciled head `ca4ae65` with 353
native tests, eight Chrome contracts and 98.54 percent line coverage. Review of
that head found three further behavioral edges: identity-less diagnostics could
carry focus inconsistent with their fixed operation block; completed Home
sessions could be resurrected by reapplying an older backup; and successful
recovery refresh reset timing for an unchanged local active question. Focused
tests and implementations are ordered separately for each behavior and are
published together for CI, without claiming unavailable local execution. The
fourth finding was the now-recorded final-head run. Exact review text is linked
as [final-head provenance][r44], [legacy diagnostic focus][r45], [stale Home
session][r46], and [active timing][r47].

The next correction stack added separate ordered tests and implementations for
legacy diagnostic focus consistency, stale Home-session suppression and timing
preservation across an unchanged recovery refresh. CI run 36304028431 passed all
356 native tests but found one Dart-formatting difference; formatter-only commit
`e7cc11c` corrected it. Final-head CI run 36304198865 then passed 356 native
tests, eight Chrome contracts and 98.54 percent line coverage, together with
formatting, static analysis, content validation, dependency-lock verification
and secret scanning.

Independent review of `e7cc11c` found five further gaps. Every supplied legacy
focus must resolve through the installed question contract; imported correction
and retest sessions must link to an originating attempt available locally or in
the payload; incompatible locally persisted pinned sessions must be retired
before Home renders; the durable-format documentation must state that creation
time and counts remain encrypted; and the correction/CI evidence above had not
yet been appended. The three behavioral changes have separate ordered local
test and implementation commits, while the envelope and provenance changes are
documentation-only. Flutter remains unavailable locally, so these commits are
published together for permitted CI and their ordering is not claimed as
per-commit execution evidence. Exact review text is linked as [latest provenance
gap][r48], [unsupported legacy focus][r49], [orphaned remediation][r50],
[envelope contract][r51], and [incompatible local session][r52].

CI run 36312515317 recorded the combined correction stack's expected integration
issues: the three new tests required Dart 3.13 formatting and the orphaned-
remediation fixture omitted the payload's required `studyState` field. Run
36312750355 then passed formatting, analysis, content validation, Chrome and the
new behavioral contracts, but exposed one older active-session fixture that
also referenced an absent originating attempt. After supplying that valid
immutable attempt, final-head CI run 36312948262 passed all gates with 359 native
tests, eight Chrome contracts and 98.50 percent line coverage. These
CI-discovered fixture/format corrections change no production behavior.

Independent review of `ceed1b7` identified five related close-out items:
restored diagnostics must remain in their ordinary question phase; active-study
correction/retest snapshots need the same originating-attempt validation as Home
sessions; in-memory recovery must expose the same chronological attempt order as
SQLite; the durable duplicate contract is semantic typed-field equality rather
than byte equality; and the 98.54-to-98.50 percent coverage movement required an
explicit investigation. The decrease followed the three preceding production
guards (legacy-focus/template validation, remediation-link validation and local
session retirement), whose new conditional paths increased the production-line
denominator. This correction adds focused business tests for the remaining
diagnostic, study-link and ordering branches rather than accepting the decrease
without investigation. Separate ordered local test and implementation commits
are retained for all three behavioral changes; local Flutter execution remains
unavailable, so combined CI is the execution evidence. Exact review text is
linked as [coverage investigation][r53], [diagnostic phase][r54], [study
remediation link][r55], [semantic duplicates][r56], and [attempt ordering][r57].

CI run 36315377511 passed formatting, analysis, content validation, eight Chrome
contracts and all new focused tests, then exposed one existing algebra journey
whose equal-time insertion order changed because the initial ordering fix sorted
every in-memory read. Commit `265a0aa` narrows sorting to recovery merges, so
ordinary recording retains insertion order while imported older attempts are
placed chronologically. Final CI run 36315594634 is fully green with 362 native
tests, eight Chrome contracts and 98.51 percent line coverage. The focused tests
recover part of the investigated 0.04-point decrease; the remaining 0.03 points
are the explicit fail-closed branches added by the earlier compatibility and
retirement guards, while all reachable business outcomes and invalid-input
contracts are exercised. No assertion or coverage threshold was weakened.

Records-head CI run 36317958110 verifies submitted head `31015fe` with all gates
green. Independent review of that head found four additional fail-closed
boundaries: Home remediation links must match session and skill, diagnostic
study snapshots must remain in question phase, review-phase Home sessions must
use the `review-` identity contract, and encrypted envelopes must reject every
field outside the exact authenticated schema. The fifth finding was the missing
records-head run above. Focused tests precede the corresponding implementations;
the two coordinator rules share one closely related test/implementation cycle.
Exact review text is linked as [records-head provenance][r58], [remediation
identity][r59], [study diagnostic phase][r60], [review identity][r61], and
[envelope keys][r62].

CI run 36327717785 exposed only mechanical fixture and formatting integration
issues in the completed correction stack. Commit `e199971` corrected those
together; CI run 36327925937 was fully green with 366 native tests, eight Chrome
contracts and 98.46 percent line coverage. Focused characterization tests then
covered the independent remediation session/skill mismatch branches and the
valid linked-study path without changing production behaviour. Run 36328201531
found that one new assertion used the internal name `hasActiveStudy` instead of
the published preview contract `hasStudyState`; all other tests passed. Commit
`01be958` corrects that test-only compile error. Commit `8af8d77` also makes the
agreed efficient publication workflow durable in `AGENTS.md`: preserve local
red/green commits, batch known review corrections, publish the completed stack
once, and reserve CI for unavailable local capabilities and final verification.
Final CI run 36331689402 is fully green with 367 native tests, eight Chrome
contracts and 98.51 percent line coverage. Formatting, static analysis, content
validation, dependency-lock verification, coverage enforcement and secret
scanning all pass.

[r1]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815397
[r2]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815400
[r3]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815402
[r4]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815405
[r5]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815410
[r6]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815415
[r7]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815418
[r8]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815427
[r9]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815429
[r10]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4058815431
[r11]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359838
[r12]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359846
[r13]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359850
[r14]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359857
[r15]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359867
[r16]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359876
[r17]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4064359882
[r18]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112324236
[r19]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112324240
[r20]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112324243
[r21]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112324250
[r22]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112610641
[r23]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112610645
[r24]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112610648
[r25]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112815871
[r26]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112815877
[r27]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112815879
[r28]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4112815883
[r29]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113202319
[r30]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113202324
[r31]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113202326
[r32]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113202333
[r33]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113615455
[r34]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113615464
[r35]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113615473
[r36]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113615476
[r37]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113711096
[r38]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113711101
[r39]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113711102
[r40]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4113711103
[r41]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114074355
[r42]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114074357
[r43]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114074358
[r44]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114269618
[r45]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114269620
[r46]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114269621
[r47]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114269623
[r48]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114874236
[r49]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114874239
[r50]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114874242
[r51]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114874245
[r52]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4114874247
[r53]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115051703
[r54]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115051708
[r55]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115051710
[r56]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115051715
[r57]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115051718
[r58]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115315025
[r59]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115315029
[r60]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115315033
[r61]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115315039
[r62]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4115315042
