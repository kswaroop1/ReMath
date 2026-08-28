# Contributing to ReMath

Thank you for helping build ReMath. Contributions must preserve offline operation,
deterministic assessment, portable learner data, original or compatibly licensed
content, and the quality requirements in `AGENTS.md`.

## Required development cycle

Behaviour changes must use the red–green–refactor process in
`docs/testing.md`:

1. select feature IDs and business acceptance criteria;
2. commit or otherwise preserve the behaviour-focused test first;
3. run it and record the expected red failure;
4. implement only enough production code to reach green;
5. refactor with the complete relevant suite green; and
6. repeat per behaviour.

Tests should express learner, content, progress, or safety outcomes wherever
possible. Bug fixes require a failing regression test first. Characterization
tests for existing behaviour precede the refactoring they protect and do not
require an artificial failure.

## Development checks

Before opening a pull request, run:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
dart run tool/check_coverage.dart 90
```

Content changes must also pass the content validator when one is present.

## Required local secret hooks

Install [pre-commit](https://pre-commit.com/) with `pipx install pre-commit`
(or another supported installation method), then activate the repository hooks:

```bash
pre-commit install --install-hooks
```

The checked-in configuration installs both mandatory gates:

- a pre-commit Gitleaks scan of staged changes; and
- a pre-push Gitleaks scan of repository history.

Verify the setup at any time with:

```bash
pre-commit run --all-files
pre-commit run --hook-stage pre-push --all-files
```

Git does not activate repository-provided hooks automatically after cloning, so
each contributor must run the installation command once per clone. CI repeats the
full-history scan and is the authoritative merge gate. Do not bypass a finding
with `SKIP`, `--no-verify`, an allowlist, or `gitleaks:allow` unless a reviewed
false-positive exception is committed with a documented justification.

If a real secret is detected, stop using it and revoke or rotate it immediately.
Removing it in a later commit is insufficient because it remains in Git history.
Never have a hook or formatter rewrite an exposed credential automatically.

## Pull requests

Keep each pull request focused. Explain the user-visible outcome, architecture or
migration impact, tests, licences, and limitations. Contributors remain
responsible for understanding, reviewing, and maintaining everything they submit.

## AI-assisted contributions

AI-assisted contributions are welcome when disclosed and held to the same quality
bar as human-written work. This includes code, tests, content, documentation,
debugging, review responses, and substantial design produced with coding agents,
chat assistants, or generative autocomplete.

Every AI-assisted pull request must:

1. check the AI-assistance declaration in the pull-request template;
2. add `provenance/ai/pr-NNNN-short-slug/metadata.yaml`;
3. add an append-only `transcript.md` containing every PR-related human prompt
   and AI response available to the contributor;
4. append later review discussions, corrective prompts, failed-build diagnosis,
   and AI-assisted fixes before merge;
5. identify tools/models when known and link relevant workflow runs;
6. state all redactions rather than silently omitting transcript sections; and
7. receive human review from someone who understands and accepts responsibility
   for the result.

Do not commit hidden system/developer instructions, model chain-of-thought,
credentials, access tokens, private keys, personal data unrelated to the change,
or third-party confidential material. Replace sensitive text with an explicit
marker such as `[REDACTED: API credential]` and explain the redaction category
in `metadata.yaml`.

If a tool cannot export a transcript, record the complete prompts supplied to it,
its material responses or edits, all subsequent steering, and the limitation.
Raw tool telemetry and routine command output may be summarized with durable
links to CI logs; output that caused a design or code change must be recorded.

AI provenance is review evidence, not a transfer of responsibility to the tool.
Undisclosed AI-assisted pull requests may be closed.


### Codex review

After the pull request is complete and its provenance record is current, request
the repository's on-demand Codex review with:

```text
@codex review
```

Codex applies the repository-wide `## Code Review Rules` in `AGENTS.md`.
Contributors must resolve substantive findings and append any AI-assisted review
discussion, diagnosis, or fixes to the provenance transcript before merge. A
Codex review is an additional signal; it does not replace CI, branch protection,
or the accountable human review required above.
