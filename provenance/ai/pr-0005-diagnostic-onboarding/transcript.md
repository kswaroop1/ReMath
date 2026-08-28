# PR 5 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Feature selection

### User

> What next

### Assistant

> The next vertical slice should be diagnostic onboarding and initial placement,
> using the existing arithmetic generators, answer contracts, local progress,
> and resumable session foundation. Proposed scope: LX-001, the CG-003
> multi-track placement foundation, and CG-004 separation of fluency and
> understanding objectives, initially for arithmetic.

### User

> Please implement pr5 fully

### Assistant

> PR #5 will be implemented as a complete vertical slice: arithmetic diagnostic
> policy, resumable diagnostic flow, persisted evidence, onboarding/results UI,
> tracker/architecture updates, and complete provenance. Each new behaviour will
> follow strict business-focused red-green-refactor commits and the PR will
> remain draft until full scope and coverage are verified.

## Acceptance criteria

- A new learner can start an arithmetic diagnostic without an account or network.
- The diagnostic samples addition, subtraction, and multiplication independently.
- Placement distinguishes rebuild fundamentals, practise speed, and ready to
  progress using accuracy and response-time evidence.
- One weak operation does not lower an unrelated operation's placement.
- The diagnostic can be interrupted and resumed without losing answered evidence
  or the current question.
- Completion persists immutable diagnostic attempts and presents an explainable
  per-operation recommendation.
- The existing drill remains available and unchanged.
- The complete slice works offline and maintains meaningful near-100% production
  coverage.
