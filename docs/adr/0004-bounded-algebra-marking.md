# ADR 0004: bounded algebra marking and evidence versions

Status: selected for PR14, implementation and verification in progress.

## Decision

Use a local exact polynomial normal form with rational coefficients for real x.
The accepted grammar has integer/finite-decimal literals, x, parentheses, unary
signs, addition/subtraction, explicit or implicit multiplication, constant
nonzero divisors, and integer powers from zero to eight. Degree, input length,
parenthesis nesting and coefficient size are bounded. Variable denominators and
functions are unsupported; no cancellation can silently erase excluded points.

Equivalence and answer form are distinct. A collected/expanded answer must be a
sum of distinct-degree monomials, not a product containing a variable sum. Exact
equivalence alone is insufficient for an instruction to collect or expand.
Linear-equation exercises request the value of x as a constant expression.

Reuse the current study controller, persistence transaction and correction loop.
A combined curriculum catalogue routes existing number skills unchanged and
new algebra skills to their immutable generators. It does not copy the controller
or create another active-session storage table. Existing number-only goals keep
the same skill sets.

Freeze template, marking and scoring versions in algebra question identity and
saved plan steps. Read old numeric steps with their existing version-one defaults;
reject unknown future versions without replacing the saved snapshot. Derived
progress remains rebuildable from immutable events. Algebra policy v1 permits
sixty seconds per fluent answer rather than inheriting twenty-second numeric
recall. Future policy changes must preserve old-version interpretation or add an
explicit replay policy; never silently relabel historical evidence.

## Consequences

No new dependency, network service or unrestricted expression evaluator is needed.
This is a bounded QA-003 foundation, not a computer algebra system. New syntax,
variables, functions or domain-changing transformations require another explicit
contract and tests. Structured reasoning and confidence evidence follow in later
increments of the accepted programme.
