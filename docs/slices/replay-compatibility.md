# Preserve seeded question contracts

Resolve merged PR15 review findings before calibration. Historical numeric and
algebra v1 identities did not distinguish browser floating-point recurrence from
native integer recurrence. PR15 then made v1 exact on every platform, so existing
browser snapshots are ambiguous between pre-PR15 and PR15 generation. Do not infer
the origin from the current device or silently regrade an old draft.

Use a new explicit template version for future exact portable numeric/algebra
questions. Preserve v1 recurrence implementations for legacy reconstruction.
Older active snapshots must retain their draft, seed and plan and explicitly
select their generator origin before answering resumes: original browser, or
native/portable. Persist that selection; future snapshots carry the generator
contract directly. Historical attempt verdicts remain immutable, and legacy
identity ambiguity is disclosed rather than claiming exact cross-device replay.

Add VM and Chrome regression fixtures for both legacy and portable generators,
active-session migration/choice/restart, invalid future versions and preserved
history. Balance diagnosis remediation must select algebra.linear, with a failing
category-specific test first. No automatic clearing of legacy sessions and no
release. Keep chronological test-first evidence in a new PR.
