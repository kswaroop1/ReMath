# Increment 3 — apply algebra

Selected feature IDs: QA-015 technique selection, QA-016 assumption identification,
LX-009 mixed challenge chunks, LX-010 application chunks and MP-009 technique
selection progress. Build on PR15 without waiting for its merge.

Learners choose a method and a modelling assumption before unlocking calculation.
Their committed choices remain visible, saved offline and locked for the current
attempt. No correctness feedback appears before calculation. An immutable final
answer retains both choices and the calculation; method evidence is reconstructed
separately, so a calculation slip cannot erase an independently correct method.
Hints/corrections remain assisted evidence and never increase independent scores.

Original bounded scenarios cover break-even, proportional scaling and constant
rate. A mixed challenge alternates these without revealing topic names or worked
lessons before an independent attempt. Application chunks include instruction;
challenges begin directly. Both use the shared correction/retest, resume, history
and prerequisite framework. Versioned identities reconstruct the exact scenario
and scoring on VM and web; malformed, unknown and duplicate evidence is tested.

This is engine coverage with a small original application set, not completion of
finance/engineering/AI syllabuses. Existing goals and historical snapshots retain
their meaning. Separate test-first and implementation commits and chronological CI
evidence remain mandatory. User merges PRs; no release is included.

Implemented through PR16 (engine) and PR17 (journey). Application answers store
method, assumption, confirmation and numeric value together in the immutable
attempt. Each independently correct method/assumption contributes half of
technique credit; numeric correctness is separate. Unsupported versions and
invalid answers are excluded, event IDs deduplicated, assistance excluded.
The application goal adds four independent skill tracks; mixed challenges skip
pre-answer teaching. No new database schema or network requirement.
