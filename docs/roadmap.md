# Delivery roadmap

This roadmap records the recommended sequence after the correction and
remediation work merged in PR #6. Each pull request remains independently
reviewable and follows the repository's strict business-focused
red–green–refactor process.

## PR #7 — Offline learning packs and hint ladder

Close the first complete learn-before-drill loop without introducing a network
or paid-AI dependency.

### Feature scope

- **LX-006 — Learn chunk:** a concise concept introduction followed by immediate
  practice inside a standard 15-minute chunk.
- **QA-021 — Hint ladder:** concept cue, method cue, next-step cue, and worked
  solution with increasing assistance.
- **MP-004 — Attempt and correction tracking:** complete the foundation with
  immutable hint and revealed-step evidence.
- Extend the content-pack contract for original offline concept cards, formula
  cards, worked examples, common mistakes, applications, and optional external
  refresher links.
- Prove the reusable contract with mental addition, subtraction, and
  multiplication resources. Broader mathematics belongs in later content packs.

### Acceptance direction

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

## PR #8 — Curriculum and prerequisite graph

Implement **CG-002**, the general part of **CG-007**, and foundations for
**CG-006** and **CG-010**: directed prerequisites, readiness recommendations,
goal-to-skill relationships, and explainable navigation. Recommendations should
guide without unnecessarily blocking exploration.

## PR #9 — Review chunks and retained mastery

Implement **LX-008**, **CG-008**, **MP-012**, and the next stage of **MP-011**:
delayed retrieval sessions, retained-success evidence, lapse handling, and
review selection based on due or at-risk skills rather than immediate accuracy
alone.

## PR #10 — Progress dashboard and skill history

Implement **MP-016** and **MP-017**, with foundations for **MP-007**, **MP-008**,
and **MP-014**: an explainable view of attempts, accuracy, fluency, assistance,
retention, and why each skill recommendation or score changed.

Learner-facing acceptance criteria:

- The dashboard distinguishes independent attempts from coached corrections and
  hints, and never presents assisted work as independent mastery.
- Every arithmetic skill shows accuracy, fluency, retained evidence, review
  timing, and an explainable knowledge/performance indicator.
- Forgetting risk rises predictably as a scheduled review approaches and is
  explicit when overdue; an unattempted skill is shown as having no evidence.
- A learner can open a skill history and understand how each answer, retest,
  correction, or hint affected—or did not affect—the displayed progress.
- Empty and partially populated histories are honest, deterministic, available
  offline, and derived without mutating persisted attempt events.

## Intended product sequence

1. Diagnose a learner's current foundation.
2. Teach or refresh the recommended concept.
3. Practise, correct, and retest it.
4. Revisit it later to confirm retention.
5. Explain progress and the next recommendation.

The roadmap is directional rather than permission to expand a pull request.
Each PR must restate its exact feature IDs and learner-facing acceptance criteria
before its first test-only commit.
