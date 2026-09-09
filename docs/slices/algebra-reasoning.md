# Increment 2 — explain algebra

Selected before implementation: QA-005/006/007/008, MP-005 foundations, and
prerequisite remediation across the shared curriculum. Continue the accepted
programme without waiting between PRs; user merges each ready PR independently.

First address PR14 review findings: constant-only linear solutions; syntactic
variable-sum form checks; portable seeded arithmetic verified on VM and Chrome;
and recommendation of prerequisites outside the selected goal. Numeric VM
identities remain unchanged. Explicit exploration remains available.

Then deliver four complete offline reasoning modes: order a short derivation,
fill a missing expression, identify the first invalid step and its error category,
and select all equivalent expressions. Every mode has deterministic identity,
original worked hints, correction/retest, saved typed drafts and progress history.
Partial credit for multiple-select is max(0, correct-selected/correct-total -
wrong-selected/wrong-total); selecting all earns zero. Only a fully correct,
independent answer advances the reasoning skill; symbolic solving remains separate.
Record error category and partial credit with immutable attempts and explain
remediation. Reuse the current session transaction and versioned evidence model.
Use keyboard/screen-reader labelled controls instead of requiring drag-and-drop.

Preserve existing numeric/algebra snapshots and history; unknown future contracts
must fail without replacing saved data. Each behavioural addition uses separate
red/green commits and CI evidence. No release or merge by the agent.
