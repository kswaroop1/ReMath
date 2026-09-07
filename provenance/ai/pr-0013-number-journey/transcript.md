# Chronological implementation record

## User scope

User: "Lets skip the release for now.  How big are these two features ma-001 and 2?  Can ww be a bit more ambitious and do a larger feature set?  Remember we were vertical slicing the features and incrementally adding core infra features."

Assistant proposed a number-fluency/proportional-reasoning vertical slice, followed
later by an algebra bridge. After a core feature status inventory, the assistant
recommended goal selection, chunk planning, generalised skill progression, MCQs
and complete session resume alongside the number content.

User: "Ok go ahead implement"

## Initial decisions

Fresh clone of merged main e305b3f avoids unrelated modifications in an earlier
workspace. Scope and acceptance were committed before implementation. Existing
arithmetic is operation-specific; the new journey will use generic skill IDs and
reuse exact marking, immutable events, and retained mastery. Legacy drills and
sessions remain accessible. No release and no new external dependencies.

Direct git push lacked credentials. Connected GitHub app created draft PR13;
local test-first history will be mirrored through Git objects in the same order.
Flutter stable was cloned to scratch for local verification. Routine download
telemetry omitted. No hidden reasoning or credentials are included.

## Cycle 1: authored curriculum and deterministic questions

Test-first contract covers all offered skills, exact division, fraction marking,
unique misconception-labelled choices, staged hints and invalid identities.
