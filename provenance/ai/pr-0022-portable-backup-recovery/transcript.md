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

Verified-head CI run 36333470103 is fully green with the same 367 native tests,
eight Chrome contracts and 98.51 percent line coverage. Independent review of
that head identified four related restored-state invariants plus the omission of
this final-head run from provenance: remediation origins must be failed answer
attempts, study remediation must target an answerable retrieval or practice
step, diagnostic study snapshots must be unassisted, and `review-` identities
must remain in review/remediation phases. In accordance with the repository's
batched-publication rule, commit `aa1ea93` states all four contracts together
before commit `f228f53` implements the guards; both local commits are published
as one stack for authoritative CI. Exact review text is linked as [verified-head
provenance][r63], [failed remediation origin][r64], [answerable study
remediation][r65], [unassisted diagnostic][r66], and [review identity
inverse][r67].

CI run 36335344015 exercised the complete batched implementation. All new
behavioral examples passed, then the run exposed three mechanical integration
issues: two older valid-remediation fixtures still used successful origins, the
new review-identity test attempted to change immutable session identity through
`copyWith`, and one test declaration differed from canonical Dart 3.13
formatting. Commit `b63e418` corrects all three together without changing the
production guards.

CI run 36341824171 passed 370 tests and every new behavior contract, then
identified one remaining valid-remediation fixture that still created a
successful origin plus the formatter's compact layout for the two corrected
fixture calls. Commit `c20cb35` corrects that final test-only integration issue;
production behavior is unchanged.

CI runs 36345313245 and 36348677592 confirmed all 371 native tests passed
while exposing only the canonical Dart 3.13 layout for three equivalent
fixture calls. Commit `2342e69` applies that mechanical layout consistently.
Final implementation-head CI run 36349567209 is fully green: formatting,
static analysis, content validation, dependency-lock verification, eight Chrome
contracts, 371 native tests, 98.52 percent line coverage and secret scanning all
pass.

Independent re-review of verified head `9cb22e0` identified five final recovery
boundaries: failed correction and retest events are valid remediation origins;
question-phase study snapshots must not retain a remediation relationship;
payload coherence must be validated against the incoming event even when a
local event with the same ID conflicts; and the restored-stack commit IDs above
needed reconciliation. Commit \`4164c2f\` states the four behavior contracts
before commit \`f303cae\` implements them. Exact review text is linked as [Home
remediation origins][r68], [study remediation origins][r69], [question-phase
relationships][r70], [restored commit identities][r71], and [conflict
preview][r72].

CI run 36360231709 passed all 375 native behavior tests and exposed only the
Dart 3.13 layout for the three new long test declarations. Commit `71cac54`
applies that canonical mechanical formatting. Final correction CI run
36364073671 is fully green across formatting, analysis, content validation,
dependency-lock verification, eight Chrome contracts, 375 native tests,
coverage enforcement and secret scanning.

Records-head CI run 36370111542 is fully green. Independent re-review of
verified head `9b9655e` found one remaining coherence boundary: a restored
correction must reference the failed attempt for its pinned current question,
not merely the same session and skill. Commit `780c8bd` states that
contract before commit `08adcca` enforces it. Exact review text is
linked as [pinned correction origin][r73].

CI run 36375438515 passed all 376 native behavior tests but exposed only
the canonical Dart 3.13 layout for the new pinned-question fixture. Commit
`d7282be` applies that mechanical formatting. Final implementation-head CI run
36381715167 is fully green: formatting, static analysis, content validation,
dependency-lock verification, eight Chrome contracts, 376 native tests, 98.52
percent line coverage and secret scanning all pass.

Records-head CI run 36384149132 verifies submitted head `878ccd5` with all
gates green. Independent review found three remaining consistency boundaries:
legacy Home corrections must compare their origin against the deterministically
resolved current question; study corrections must bind to their generated
current question while retests retain their intentional next-question behavior;
and export must not combine attempts and active state observed on opposite sides
of a concurrent commit. Commit `ff7131a` states all three contracts before
commit `bff3a12` implements resolved identity checks and a bounded stable-
snapshot retry. Exact findings are [records-head provenance][r74], [legacy
correction identity][r75], [study correction identity][r76], and [consistent
export snapshot][r77].

CI runs 37068583001, 37069823698, and 37078340924 confirmed all 379
native behavior tests while isolating a Dart 3.13 formatter-only mismatch in the
backup coordinator. Diagnostic CI run 37082308650 printed the exact canonical
diff because local Flutter execution remained unavailable; commit `8be7351`
restores the normal formatting gate and applies that output. Final correction-
head CI run 37085470873 is fully green across formatting, static analysis,
dependency-lock and content validation, the Chrome contract suite, all 379
native tests, coverage enforcement, and secret scanning. The four records-head
review findings are answered with their red/green commits and this verification.

Records-head CI run 37088830717 verifies submitted head `b8182e0` with every
gate green. Independent review found that the retry cannot cover the interval
between Home attempt persistence and its next session-state persistence, so
commit `1096fcc` states an atomic repository-snapshot contract before commit
`b5557a2` implements it for production SQLite and in-memory repositories.
Commit `315d797` also replaces the obsolete Android warning with the shipped
encrypted backup/recovery steps. Exact findings are [records-head
verification][r78], [atomic Home snapshot][r79], [Android recovery
instructions][r80], and [batched TDD disclosure][r81].

Process disclosure: the earlier `ff7131a` / `bff3a12` cycle batched three
distinct review corrections into one red commit and one green commit. Although
the tests preceded implementation and remain independently focused, that
history does not satisfy the repository rule requiring separate red/green
commit pairs for differing behaviors. It is retained rather than rewritten and
recorded here as a TDD-process deviation. The new atomic-snapshot behavior uses
its own separate red/green pair.

Batch-head CI run 37103219762 passed all 379 behavior tests but exposed one
Dart 3.13 formatting mismatch in the focused atomic-snapshot test. Commit
`7da4fdf` applies the formatter's canonical layout without changing behavior;
CI run 37104305649 then verifies the complete correction head with every gate
green. The four review threads are answered with their commits and that final
verification.

Records-head CI run 37104503538 verifies submitted head `59b8218` with every
gate green. Independent review then identified three further behavior
boundaries: Home attempts and their resulting session transition must commit
atomically rather than merely be read atomically; repeated multiple-choice
remediation records the canonical base question identity; and unresolved
legacy study state must preserve its pre-origin-suffix identity until the
learner chooses a generator. Commit `c81f541` states the two study-identity
contracts before `37efd9f` implements their phase-aware canonical comparison.
Commit `798cc99` states the atomic Home-transition repository contract before
`a489c4f` implements it for in-memory and SQLite persistence and routes Home
submission through that transaction. Exact findings are [atomic Home
transition][r82], [records-head verification][r83], [multiple-choice
remediation identity][r84], and [unresolved legacy identity][r85].

Batch CI run 37110105815 passed 382 tests and exposed the complete remaining
failure set: the new legacy fixture used a non-existent skill identifier, and
SQLite's two-interface declaration differed from Dart 3.13 canonical layout.
Commit `ea69f29` corrects the fixture to the published `number.fractions` skill
and applies the formatter's tall declaration layout together before rerunning
the full suite.

CI run 37113959500 confirms all 383 behavior tests pass but the SQLite file
still differs from Dart 3.13 canonical formatting. Because local Flutter
execution is unavailable and two inferred layouts were rejected, the next
bounded diagnostic run temporarily prints the formatter diff; the diagnostic
workflow change will be reverted with the exact correction.

Diagnostic CI run 37115022260 passed all 383 behavior tests and printed the
exact remaining formatter changes: the compact two-interface declaration and
the tall argument-list layout for the session deletion. Commit `8b524d6`
applies that output and restores the normal non-mutating formatting gate. The
diagnostic also showed Flutter regenerating the existing macOS plugin
registrant after dependency installation; that transient generated diff is not
part of the Dart formatting gate or this correction.

Final correction-head CI run 37119459425 is fully green across formatting,
static analysis, dependency-lock and content validation, Chrome contracts, all
383 native tests, coverage enforcement, and secret scanning. The four review
threads are answered with the focused red/green commits and this verification.

Records-head CI run 37123443291 verifies submitted head `35da773` with every
gate green. The final independent review then identified remediation-integrity
boundaries for successful hinted study answers, Home and study retest identity,
atomic Home hint transitions, assisted-state calibration, and observable
controller routing, together with four records corrections. Commit `1d62f04`
defines those behavior contracts before `fde7365` implements them.

Process disclosure: `c81f541` batched the repeated-MCQ and unresolved-legacy
contracts in one red commit and `37efd9f` implemented them in one green commit,
so that cycle did not provide the distinct red/green pairs required for separate
behaviors. In addition, the unresolved-legacy example in `c81f541` used the
nonexistent `fractions.addition` skill and failed during state decoding rather
than at the intended identity boundary; the valid `number.fractions` fixture
first appears in `ea69f29`, after its production implementation. The repository
history is preserved and both facts are recorded as TDD-process deviations.

The original atomic-transition red commit `798cc99` exercised the repository
operation directly but did not observe `LearningController` routing. Production
routing first appeared in `a489c4f`; controller-level answer and hint routing is
therefore explicitly covered in `1d62f04`, and the earlier production-first gap
is retained here as a TDD-process deviation.

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
[r63]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4116107216
[r64]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4116107219
[r65]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4116107223
[r66]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4116107228
[r67]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4116107231
[r68]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4117429406
[r69]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4117429408
[r70]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4117429415
[r71]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4117429417
[r72]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4117429420
[r73]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4118305418
[r74]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4119606371
[r75]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4119606376
[r76]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4119606383
[r77]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4119606392

[r78]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4171534564
[r79]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4171534570
[r80]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4171534571
[r81]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4171534574
[r82]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4172097375
[r83]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4172097382
[r84]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4172097388
[r85]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4172097392
[r86]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395534
[r87]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395537
[r88]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395541
[r89]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395544
[r90]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395547
[r91]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395550
[r92]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395551
[r93]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395553
[r94]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395560
[r95]: https://github.com/kswaroop1/ReMath/pull/22#discussion_r4173395563

Final review integration CI 37130458568 exposed a missing required studyState argument and a controller fixture that did not enter Learn mode. Commit `51ca9e9` corrects those fixtures; CI 37131508974 passes all 388 native tests, with only formatting remaining. Diagnostic CI 37135751696 again passes all 388 tests and supplies the exact two test-file formatting deltas applied in the following formatting commit, which also restores the normal non-mutating gate. Generated analysis-options and macOS registrant differences printed by the diagnostic are dependency-installation changes, not Dart formatter changes. Local SDK execution remains unavailable.

Final-head CI run 37140196085 verifies `e7d1dc0` with every gate green and
all 388 native tests passing. Independent review then identified two remaining
native-state boundaries: hinted multiple-choice first answers retain their MCQ
identity when they become retest origins, and Home remediation roots permit
failed answers and retests but not failed corrections. Published commit
`c2bd9ec` defines both contracts before `3b6e525` implements their
phase-specific validation. Combining those separate recovery contracts in one
red/green pair is an additional TDD batching deviation; the history is
preserved and is not presented as separate compliant cycles.

Process disclosure: published red `1d62f04` combined distinct backup-validation
and atomic Home-hint contracts, with their implementation combined in
`fde7365`; this does not satisfy the separate-pair rule. That red commit also
stopped at an omitted required argument and a controller fixture that never
entered Learn mode, corrected only in `51ca9e9` after production implementation.
The shared cycle is therefore recorded as both a batching deviation and a
production-first TDD deviation rather than compliant test-first evidence.

CI 37147954291 verified formatting, analysis, content packs, browser contracts,
and 388 native tests at `0b7254e`, but exposed one contradictory legacy test:
it still listed `AttemptKind.correction` among accepted Home remediation roots
while the adjacent final-review regression correctly rejects that same kind.
The acceptance contract is failed answer or failed retest for Home, so the
legacy parameterized example is corrected to cover answer and retest. This is
a requirement/test reconciliation, not new production behaviour; the final
review's production restriction remains unchanged.

Replacement CI 37151224357 verifies commit `116c2fb` with every gate green,
including all 389 native tests and the Chrome browser contracts. This is the
authoritative final behavioural-head verification after reconciling the
contradictory legacy Home-remediation example.

Records-head CI 37154693406 verifies `c167e67` with every gate green. The final
independent review of that head identified four further native Study-state
boundaries: distinguish hinted first answers from intermediate corrections,
preserve failed hinted MCQ identity, permit confidence on independent retests,
and validate a retained causal remediation root across repeated assisted
retests. Each boundary is addressed in its own ordered local red/green pair;
local Flutter execution remains unavailable, so the focused missing-behaviour
failures are established by the reviewed pre-fix conditions and the complete
published stack receives one authoritative CI run.

CI 37161632268 confirmed three new Study boundaries and the retained-chain
contract, but exposed two batch defects together: one canonical formatting
change in `backup_coordinator.dart`, and the confidence test's feedback-lock
fixture omitted the required answer draft. Because the latter setup defect was
corrected only after its production condition changed, that confidence cycle
is recorded as a production-first TDD deviation rather than valid red evidence.
The other three focused pre-fix tests exercised their intended boundaries.

Replacement CI 37164488533 passes all 392 native tests. Its only remaining
failure is the formatter's single-line layout for the 78-column retained-chain
helper signature; the canonical Dart 3.13 layout is applied without behavioural
change in the following commit.

Final implementation CI 37167419811 verifies `848cb9c` with every gate green,
including all 392 native tests and the Chrome browser contracts. This is the
authoritative behavioural-head verification for the complete final Study-state
review batch.

Records-head CI 37171935009 verifies `81adfc1` with every gate green. The
subsequent independent review identified five remaining boundaries: prove each
intervening assisted Study transition in a retained retest chain, bound work for
an untrusted question index, reload persisted Home state after duplicate atomic
answer and hint transitions, keep SQLite merge reads synchronous inside the
transaction, and append this records-head result.

Those behavioral corrections were developed as three separate local red/green
pairs and published together: retained-chain and bounded-validation commits
`d2f66ca` / `764d0ad`, duplicate Home-transition commits `e697764` /
`fc4feeb`, and synchronous SQLite-transaction commits `b894a2d` / `eb71cb2`.
The retained-chain and work-bounding contracts were combined in the first pair,
so that pair is an additional TDD batching deviation rather than two compliant
cycles. Local Flutter execution was unavailable for all three pairs and no
executed red result exists for their test commits; their ordering is preserved,
but they are recorded as unverified red/green process deviations rather than
verified red evidence.
CI 37177068872 passed all 396 native tests but failed only because the new
retained-chain regression required canonical Dart formatting. Commit `fc43f34`
applies that formatter-only change. Replacement CI 37178577618 verifies it with
every gate green, including all 396 native tests and the Chrome contracts.

Records-head CI 37183235074 verifies `58ad11b` with every gate green. Review of
that head identified a phase-specific identity defect in retained MCQ retest
chains: native assisted retest transitions omit the question-phase `.mcq`
suffix. Local test commit `0ad40b3` changes the retained-chain fixture to the
native identity, and local implementation commit `6cc1de8` validates each
intervening transition using its retest remediation identity. Local Flutter
execution remains unavailable, so this ordered pair likewise has no executed
red result and is not overstated as verified red evidence.

Published commits `e96f35e` / `5aad2db` preserve that ordered test and
implementation history, with provenance commit `d4dc26d`. CI 37189729173
passed all 396 native tests but identified one canonical formatter wrap in the
new validation. Formatter-only commit `4239aaf` applies it, and replacement CI
37192721533 verifies every gate green, including the Chrome contracts.

Records-head CI 37196254175 verifies `0993c3f` with every gate green. Review of
that head identified an impossible Home state still accepted by preview: a
retest at question index zero has no preceding question from which native Home
remediation could have advanced. Local test commit `7687253` defines that
boundary before local implementation commit `d2e272d` rejects it. Local Flutter
execution remains unavailable, so this pair has ordered test/implementation
history but no executed-red evidence and is recorded accordingly.

Published commits `883b0dc` / `576997f` preserve that ordered test and
implementation history, with provenance commit `1845de2`. CI 37201641675
passed all 397 native tests but found only a canonical formatter change in the
new regression. Two manual formatter guesses in commits `72bdb6b` and
`b87533a` were incorrect because the blocked environment did not expose the
current Dart formatter. Diagnostic commit `b235d08` temporarily printed the
CI-generated patch; commit `33decb5` applies that exact patch and restores the
normal non-mutating formatting gate. Diagnostic runs 37206860494,
37213954042, and 37220943099 all passed the full 397-test suite while failing
only formatting. Replacement CI 37223183993 verifies `33decb5` with every gate
green, including Chrome browser contracts and all 397 native tests.

Records-head CI 37228656684 verifies `c3f173d` with every gate green. Review of
that head identified one remaining runtime boundary: rejecting an idempotent
duplicate answer must not reset the active question's response-time origin.
Local test commit `341e7a4` extends the existing duplicate-transition contract
to retry with a fresh event ID and require the full five-second response time;
local implementation commit `52409f4` advances `_questionBeganAt` only after a
successful insertion. Local Flutter execution remains unavailable, so this
ordered pair has no executed-red evidence and is recorded accordingly.

CI 37235207348 passed formatting, analysis, content validation, browser
contracts, and the full pre-existing suite, but the new timing regression's ID
fixture advanced to a fresh answer one transition too early. Commit `d2bfd58`
adds the missing duplicate ID so the first answer is rejected before the fresh
retry. Because this fixture correction follows the production change, the
timing cycle is additionally recorded as a production-first TDD deviation
rather than compliant executed-red evidence.

Replacement CI 37238111650 verifies `7bc6d99` with every gate green, including
all 398 native tests and the Chrome browser contracts. This is the
authoritative behavioural-head verification for the duplicate-answer timing
correction.

Records-head CI 37243112518 verifies `f37347b` with every gate green. Review of
that head identified three remaining import boundaries: every retained assisted
Study transition needs both hint and correction evidence; an identity-less,
unfocused legacy Home session must not resume after merged local history changes
its scheduler context; and selected backup size must be checked before bytes are
materialized.

Local commits `265913f` / `37d07b5`, `d143d4f` / `0f48fc2`, and `fbeb23c` /
`bb602d1` preserve separate test/implementation ordering for those three
boundaries. Local Flutter execution remains unavailable, so these pairs have no
executed-red evidence and are not overstated as verified red/green cycles.

CI 37255840455 verified the retained-hint and legacy-session regressions but
failed the final stack on two canonical test-format changes and a file-picker
API detail: its reported length is nullable. The following corrective commit
rejects an unavailable length without reading, preserving the fail-closed size
boundary, and applies the canonical multiline test layout.
