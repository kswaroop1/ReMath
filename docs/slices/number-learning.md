# Number fluency and proportional reasoning

## Scope and acceptance (selected before implementation)

MA-001/002; LX-002/003/004/005; QA-004; CG-003/004/005;
MP-007/011/012/015/016/017 foundations.

Deliver one offline vertical slice with number-fluency and proportional-reasoning
goals. Cover addition, subtraction, multiplication, exact division, number bonds,
estimation, fractions, decimal conversion, ratios, percentages and metric units.
Each skill has original teaching, examples, four hints, deterministic numeric
questions and misconception-labelled MCQs, with three bounded difficulty levels.

- Persist the chosen goal and offer an explainable fifteen-minute plan containing
  retrieval, learning, practice, correction/retest and reflection. Permit repeated
  sessions and explicit exploration of a skill despite prerequisite advice.
- Derive per-skill placement and difficulty from independent evidence; hints and
  corrections must not advance unaided mastery. Prefer due review and then unmet
  prerequisites. Keep retained mastery separate from immediate accuracy.
- Persist the exact plan, current question identity, draft/choice, hint state,
  correction/retest phase and remaining active time. Closing the app must not
  consume the remaining budget. Commit attempts with session advancement atomically
  so interruption or retry cannot duplicate evidence or skip a question.
- Show progress and event explanations for all supported skills. Preserve legacy
  arithmetic attempts and active sessions, and keep the existing drill available.
- Use the existing exact numeric markers and retained-mastery policy. Do not add
  network dependencies, paid AI, sync, symbolic marking or a release.

MA-001/002 remain broad modules; this slice does not claim all possible content
within those modules. Goal selection covers the two usable bundled goals rather
than advertising unsupported advanced courses.

## Verification

Record each test-first commit, intended red failure, green result and final
format/analyse/full-suite/coverage results in the PR provenance record.
