# AI contribution provenance

This directory stores review evidence for AI-assisted pull requests. It is
separate from application source and product documentation because it records
the production history of a change.

## Layout

```text
provenance/ai/
  README.md
  pr-0003-short-slug/
    metadata.yaml
    transcript.md
```

Use the four-digit pull-request number. If work begins before a PR number exists,
open a draft PR first and then create its directory.

`metadata.yaml` follows this minimal structure:

```yaml
schema_version: 1
pull_request: 3
title: Short title
human_owner: github-login
agents:
  - product: OpenAI Codex
    model: unknown-or-model-name
started_at: 2026-08-27T00:00:00Z
finalized_at: null
scope:
  - code
  - tests
redactions:
  - category: credentials
    reason: Never commit secrets
ci_runs: []
```

`transcript.md` is chronological and append-only within the PR. Use headings
for user, assistant/agent, reviewer, and CI-derived follow-ups. Preserve exact
prompts and material responses where export is available. Summaries are allowed
only for routine tool output; output that influenced a decision or fix must be
included or linked.

The record must be updated after reviews and failed builds and finalized before
merge. Never include hidden system instructions, chain-of-thought, secrets, or
unrelated personal/confidential information. Mark every omission explicitly.
