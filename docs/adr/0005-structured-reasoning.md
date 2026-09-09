# ADR 0005: structured reasoning through the shared journey

Status: implemented in PR15 (increment 2).

Structured questions implement StudyQuestion and retain the existing immutable
attempt plus snapshot transaction. Order/select drafts are JSON arrays of stable
option IDs; diagnosis drafts name a step and category; missing expressions remain
text. Human labels and worked solutions are independent of this serialization.

Multiple-select credit is max(0, correct selections / correct alternatives minus
wrong selections / wrong alternatives). Empty, duplicate and unknown selections
are invalid. Only complete correctness is an independent success. Partial credit
is a deterministic projection of the immutable answer and versioned template,
not a mutable replacement for the attempt's correctness. Recognition/reasoning
skill IDs remain separate from symbolic fluency skills.

Wrong answers retain the standard correction and fresh same-skill retest. Stable
misconception identifiers record the demonstrated error category, without claiming
an unobserved psychological cause. A correction can open its declared prerequisite
lesson; assistance is recorded before showing that lesson, and the current draft
and question remain intact.

The UI uses labelled buttons, checkboxes and chips for keyboard and accessibility
support. Ordering is built by selecting steps in sequence, with removal to revise
an answer; no drag-and-drop is required. Existing version-one/two numeric and
algebra snapshots keep their contracts. Unsupported reasoning identities never
establish mastery and unsupported snapshots are retained rather than replaced.
