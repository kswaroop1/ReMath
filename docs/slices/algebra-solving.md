# Algebra reasoning: increment 1 — solve algebra

Selected before implementation: QA-003 (bounded symbolic answers), LX-002
(algebra goal), CG-003/004 (independent algebra placement), LX-005 (symbolic
resume), MP-020 (versioned scoring foundation), MA-004/005 (bounded content).

The accepted programme has four independently reviewable increments: solve
algebra; explain algebra; apply algebra; calibrate and continue. This PR delivers
solve algebra. Subsequent increments add structured steps, multi-select,
method/assumption assessment, challenges, confidence and configurable sessions.

## Learner acceptance

- Select an algebra goal and diagnose, learn, practise, correct, retest and review
  collecting terms, expansion and linear equations through the existing journey.
- Mark equivalent one-variable polynomials exactly over real x, with rational
  coefficients, parentheses, unary signs, implicit multiplication and bounded
  nonnegative integer powers. Permit division only by nonzero constants. Reject
  unsupported syntax, functions, extra variables and variable denominators as
  invalid input, never as guessed mathematical equivalence.
- Distinguish equivalence from requested form: expansion requires an expanded
  answer; collecting terms requires collected form. Explain the input contract.
  Linear-equation questions explicitly ask for the value of x, accepting exact
  constant expressions such as 3/2.
- Preserve typed symbolic drafts, hints, correction/retest phase, current marking
  version and scoring version through interruption. Old number snapshots and
  attempt evidence continue to work. Unknown versions fail without overwriting
  saved data.
- Record symbolic marking/scoring versions in immutable question identities.
  Algebra fluency has its own explicitly versioned timing policy; assistance and
  MCQs never count as independent symbolic fluency.
- Every offered skill has original teaching, four worked hints, deterministic
  bounded questions at three levels and a separately explained progress record.
- Keep the existing numeric journey and legacy drill usable. No new dependency,
  release, cloud service or general-purpose CAS is required.

## Verification

Separate test-first commits precede each behaviour implementation. CI provides
formatting, fatal analysis, full tests and near-100% meaningful coverage. Verify
exact identities, invalid/resource-limited input, equivalent but wrong-form
answers, persistence/migration, correction, keyboard focus and legacy regression.
