# Contributing to ReMath

Thank you for helping build ReMath. Contributions must preserve offline operation,
deterministic assessment, portable learner data, original or compatibly licensed
content, and the quality requirements in `AGENTS.md`.

## Development checks

Before opening a pull request, run:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

Content changes must also pass the content validator when one is present.

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
