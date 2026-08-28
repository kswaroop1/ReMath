# PR 7 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Feature selection

### User

> Merge and implement next planned pr

After PR #6 was merged, the exact earlier PR #7 numbering could not be recovered
from the repository or retained conversation context. Codex asked which open
priority should be next.

### User

> Please recommend the next set of features to i.plement

### Assistant recommendation

Codex recommended that PR #7 add the first complete learn-before-drill
experience: LX-006 Learn chunks, QA-021 hint ladder, completion of MP-004 with
immutable hint/revealed-step evidence, an offline learning-resource content
contract, and initial mental addition/subtraction/multiplication resources.

It recommended the subsequent sequence:

- PR #8: curriculum and prerequisite graph;
- PR #9: review chunks and retained mastery;
- PR #10: progress dashboard and skill history.

### User

> Please make note of ypur recommendations first

### Assistant action

Codex created `docs/roadmap.md`, linked it from the README and feature register,
and recorded feature IDs, boundaries, acceptance direction, and the rule that
roadmap inclusion alone does not mark a feature complete. This planning and
provenance commit precedes any PR #7 production behavior or tests.

## Initial acceptance direction

- A remediation recommendation opens the matching concept card.
- A learner can start and resume a Learn chunk, including revealed hint state.
- Core explanations, examples, hints, and practice work entirely offline.
- Assistance remains immutable, idempotent evidence and cannot count as
  unaided mastery.
- Optional external links are never required to complete a chunk.
- Content validation rejects incomplete, malformed, unlicensed, or unsafe
  learning resources.
- Permanent CI retains fatal warnings/infos, secret scanning, and meaningful
  production coverage at or near 100%.
