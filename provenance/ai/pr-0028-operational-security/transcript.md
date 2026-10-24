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
