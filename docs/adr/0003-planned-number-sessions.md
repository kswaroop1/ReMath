# ADR 0003: planned number sessions

Status: implemented incrementally in PR13.

## Context

The existing arithmetic controller chooses among three operations. Number learning
needs skill identifiers, fractions/decimals, multiple-choice questions, an explicit
learning plan and stable question selection after interruption.

## Decision

Add a skill-based number journey alongside the existing drill. Reuse the same
immutable attempt table, exact numeric answer contracts and retained-mastery
calculator. Existing arithmetic skill IDs retain their meanings and their old
history contributes to the new progress view. The legacy active-session record
remains intact.

A study snapshot contains the selected goal, frozen plan, seed, question index,
level, phase, draft or selected choice, revealed hints, event serial, response time
and remaining active budget. Template version 1 is immutable. Future generator
changes require a new version plus replay support for unfinished version-1 plans.

Progress schema six adds a singleton study-state table. Recording an attempt and
saving the next snapshot is one synchronous SQLite transaction. An existing event
ID makes retry a no-op, including no snapshot rewind. The controller can reload
the committed snapshot after a lost acknowledgement. Draft saves and actions are
serialized within the controller.

A plan freezes difficulty until its next chunk. Three fluent independent numeric
successes at the current level raise difficulty; two errors reduce it. Assisted
answers never promote difficulty. MCQ results are distinguishable by an explicit
question-ID suffix and do not independently establish numeric fluency or retained
mastery. Retention continues to require separate delayed occasions.

## Consequences

No cloud account, content download or AI service is required. New and legacy
sessions can be resumed independently, while both contribute immutable events to
one history. The old dashboard remains specific to the legacy arithmetic flow;
the number journey exposes progress for every bundled number skill.

The active timer is checkpointed with interactions and lifecycle pause events;
its UI also checkpoints at one-second intervals. A force-kill can lose at most the
unpersisted interval of active time, while every committed answer retains its
exact resulting state. Time spent with the app paused is not charged.

The fifteen-minute budget is an upper bound for the initial bounded plan, not a
requirement to keep an accomplished learner answering filler questions. Reflection
can finish it early, and another chunk may start immediately.
