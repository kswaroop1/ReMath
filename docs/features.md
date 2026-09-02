# Feature register

The recommended implementation order for the next bounded feature sets is
recorded in the [delivery roadmap](roadmap.md). This register remains the
authoritative status of individual features; roadmap inclusion alone does not
mark a feature complete.

This is the authoritative, numbered product and content backlog for ReMath.

## Tracking convention

- [x] means implemented, committed, and verified.
- [ ] means not complete. Its description may state **Foundation**, **Next**,
  **Planned**, or **Later** to indicate sequence.
- A checked engineering foundation does not imply that the user-facing learning
  capability built on it is complete.
- Feature IDs are permanent. Retired features remain recorded rather than being
  renumbered.

Last reviewed: 29 August 2026.

## 1. Product foundations

- [x] **PF-001 — Cross-platform Flutter foundation.** Flutter application shell
  committed for Android, iOS, Windows, macOS, and optional web generation.
- [x] **PF-002 — Responsive foundation screen.** Minimal Material 3 screen that
  renders under widget test and constrains content on wide displays.
- [x] **PF-003 — Repository working contract.** Repository-wide `AGENTS.md`
  covering architecture, data invariants, testing, dependencies, and content.
- [x] **PF-004 — Architecture documentation.** Offline-first, layered system
  boundaries and event-based synchronisation documented.
- [x] **PF-005 — Content-pack specification.** Versioned, signed, independently
  downloadable curriculum pack model documented.
- [x] **PF-006 — Testing strategy.** Test pyramid, deterministic-test rules, and
  coverage policy documented.
- [x] **PF-007 — Feature register.** Numbered backlog with explicit completion
  checkboxes and durable IDs.
- [ ] **PF-008 — Product terminology glossary.** **Planned.** Canonical meanings
  for skill, concept, template, question instance, attempt, mastery, and chunk.
- [ ] **PF-009 — Architecture decision records.** **Planned.** Record material
  package, database, sync, marking, and security choices as ADRs.

## 2. Learning experience and 15-minute chunks

- [x] **LX-001 — Diagnostic onboarding.** The offline arithmetic diagnostic
  samples addition, subtraction, and multiplication independently, resumes an
  interrupted question and draft, and explains each starting recommendation.
  Algebra, calculus, probability, and further tracks remain planned extensions.
- [ ] **LX-002 — Goal selection.** Choose goals such as JEE fluency, quant
  finance, AI-paper comprehension, engineering mathematics, or robotics.
- [ ] **LX-003 — Fifteen-minute chunk planner.** Assemble a bounded session from
  retrieval, explanation, focused practice, correction, and reflection.
- [ ] **LX-004 — Multiple chunks per day.** Permit any number of independent
  chunks without imposing one daily session.
- [ ] **LX-005 — Exact pause and resume.** Persist question, timer, answer draft,
  hint state, and remaining chunk plan.
- [x] **LX-006 — Learn chunk.** Open an offline concept card directly or from a
  remediation recommendation, reveal staged help, and retain the active card
  and revealed state across interruption. Focused practice follows through the
  existing drill and correction loop.
- [x] **LX-007 — Drill chunk.** A resumable 15-minute mental-arithmetic drill
  records locally marked answers, keeps keyboard focus on answer entry between
  submissions, and advances through generated questions. Foundation addition
  and subtraction use operands through 19; multiplication uses single-digit
  factors so mixed drills do not introduce two-digit factors prematurely.
- [x] **LX-008 — Review chunk.** A resumable focused 15-minute chunk selects the
  most urgent overdue or approaching previously learned skill.
- [ ] **LX-009 — Challenge chunk.** Unlabelled, unfamiliar, multi-topic problems.
- [ ] **LX-010 — Application chunk.** Finance, AI, computing, engineering, or
  robotics problem context.
- [ ] **LX-011 — Paper-reading chunk.** Decode one equation, paragraph, figure, or
  modelling choice from a technical paper.
- [ ] **LX-012 — End-of-chunk choices.** Stop, repeat, continue topic, review, or
  attempt a challenge. The foundation drill now offers stop, same-skill,
  weakest-skill, and mixed-drill choices; explicit review and challenge routes
  remain to complete this feature.
- [ ] **LX-013 — Configurable intensity.** Two-minute drill, standard 15-minute
  chunk, or chained study block.
- [ ] **LX-014 — Confidence capture.** Optional pre-answer confidence and
  post-answer surprise.
- [ ] **LX-015 — Distraction-safe mode.** Minimal full-screen question interface
  with optional sound and haptic feedback.
- [ ] **LX-016 — Keyboard-first desktop operation.** Complete session without a
  pointing device.
- [ ] **LX-017 — Learning accessibility.** Screen-reader semantics, scalable text,
  high contrast, reduced motion, and colour-independent feedback.
- [ ] **LX-018 — Personal preferences.** Timing visibility, notation, difficulty,
  calculator policy, and preferred application domains.

## 3. Curriculum graph and progression

- [x] **CG-001 — Stable skill identifiers.** Foundation skills use durable dotted
  identifiers independent of presentation and content-pack paths.
- [x] **CG-002 — Prerequisite graph.** Schema-v3 skills publish validated,
  acyclic directed dependencies rather than one fixed linear course.
- [x] **CG-003 — Multi-track placement foundation.** Arithmetic operations retain
  independent placement evidence, so weakness in one does not lower another.
  Cross-subject placement remains planned.
- [x] **CG-004 — Skill-level objectives foundation.** Arithmetic placement
  distinguishes rebuilding understanding from fluency practice and progression.
  Derivation and technique-selection objectives remain planned.
- [x] **CG-005 — Difficulty calibration.** A validated multidimensional profile
  preserves complexity, combined ideas, algebraic burden, abstraction, and time
  pressure without forcing incomparable burdens into one score.
- [x] **CG-006 — Unlock policy.** Readiness explanations recommend prerequisite
  preparation while every skill remains available through “Explore anyway”.
- [x] **CG-007 — Prerequisite remediation.** Repeated or characteristic errors
  retain their deterministic policy, then use the general graph to recommend the
  first unmet precursor skill.
- [x] **CG-008 — Retention prerequisites.** Durable mastery requires three
  successful occasions separated by expanding review intervals; immediate
  repetition does not advance retained mastery.
- [ ] **CG-009 — Curriculum map UI.** Foundation delivered: learners can browse
  goals, contributing skills, readiness, gaps, and non-blocking learning paths.
  Rich dependency visualization, strengths, and alternate-path comparison remain.
- [ ] **CG-010 — Goal-to-syllabus mapping.** Foundation delivered: schema-v3
  goals explicitly map skills to JEE, quant-finance, and AI-mathematics outcomes.
  Full Oxbridge, computing, robotics, and versioned syllabus coverage remains.
- [ ] **CG-011 — Syllabus-version migration.** Preserve progress when concepts
  split, merge, move, or are superseded.
- [ ] **CG-012 — External benchmark mapping.** Map original ReMath objectives to
  public learning outcomes without copying protected assessment content.

## 4. Question and assessment engine

- [x] **QA-001 — Deterministic question identity.** The foundation arithmetic
  generator reproduces a question from its versioned ID, seed, and index.
- [x] **QA-002 — Numeric short answers.** Exact integer, reduced rational,
  exact decimal, absolute-tolerance, and significant-figure contracts use exact
  local arithmetic and distinguish incorrect from invalid input.
- [ ] **QA-003 — Symbolic short answers.** Algebraic equivalence with explicit
  assumptions and domain restrictions.
- [ ] **QA-004 — Single-answer MCQ.** Randomised distractors with misconception
  metadata and guessing correction.
- [ ] **QA-005 — Multiple-select questions.** Partial-credit policy that does not
  reward indiscriminate selection.
- [ ] **QA-006 — Ordered-step questions.** Arrange derivation, algorithm, or proof
  steps.
- [ ] **QA-007 — Missing-step questions.** Supply an equation, justification, or
  transformation in a structured derivation.
- [ ] **QA-008 — Invalid-step diagnosis.** Identify the first incorrect inference
  and classify the error.
- [ ] **QA-009 — Matching questions.** Formula-to-condition, method-to-problem, or
  distribution-to-property mappings.
- [ ] **QA-010 — Graph and diagram questions.** Read, manipulate, or annotate
  plots, geometric objects, computational graphs, and state diagrams.
- [ ] **QA-011 — Matrix and tensor input.** Efficient structured entry on phone
  and desktop.
- [ ] **QA-012 — Proof ordering.** Structured proof assessment without requiring
  generative AI.
- [ ] **QA-013 — Counterexample questions.** Select or construct a counterexample
  under constrained input.
- [ ] **QA-014 — One-sentence intuition.** Rubric-guided self-assessment initially;
  optional local or external AI assessment later.
- [ ] **QA-015 — Technique-selection scenarios.** Choose plausible methods before
  calculating.
- [ ] **QA-016 — Assumption identification.** Determine missing conditions,
  modelling assumptions, and theorem applicability.
- [x] **QA-017 — Parameterised generators.** Foundation arithmetic generation is
  operand-bounded, exactly marked, template-versioned, and deterministic.
- [x] **QA-018 — Generator property tests.** A 30,000-identity seeded sweep
  verifies current arithmetic templates for bounds, valid domains, unique
  identities, deterministic replay, and stable exact marking.
- [ ] **QA-019 — Curated challenge bank.** Individually authored multi-topic
  JEE/Oxbridge/university/professional-style questions.
- [x] **QA-020 — Common misconception distractors.** The arithmetic foundation
  derives deduplicated operation-confusion alternatives, excludes correct
  answers, and records stable misconception identifiers for feedback.
- [x] **QA-021 — Hint ladder.** Concept cue, method cue, next step, and worked
  solution reveal in order; each reveal is immutable assistance evidence and
  never contributes as unaided mastery.
- [x] **QA-022 — Correction loop.** An ordinary-drill error is preserved, must be
  corrected, and is followed by a nearby same-operation retest. Both phases and
  drafts resume after interruption; diagnostic placement remains independent.
- [ ] **QA-023 — Timed rapid-fire mode.** Low-friction mental and symbolic fluency.
- [ ] **QA-024 — Mixed-topic assessment.** Do not reveal the technique through the
  section heading.
- [ ] **QA-025 — Calculator policy.** Per-question mental, paper, basic-calculator,
  symbolic-tool, or coding permission.
- [ ] **QA-026 — Confidence-aware scoring.** Distinguish lucky guesses,
  overconfidence, and well-calibrated knowledge.
- [ ] **QA-027 — Question-quality review state.** Draft, reviewed, calibrated,
  challenged, and retired lifecycle.
- [ ] **QA-028 — Source and licence metadata.** Original-author or compatible
  licence evidence for every curated item.
- [ ] **QA-029 — Copyright guardrail.** Never copy commercial exam banks, course
  text, diagrams, or solutions; create original questions aligned to public
  objectives.
- [ ] **QA-030 — Assessment accessibility.** Equivalent non-visual alternatives
  where a diagram is not intrinsically required.

## 5. Mastery, repetition, and progress

- [x] **MP-001 — Immutable attempt events.** Answer attempts use unique event IDs;
  SQLite primary-key insertion makes duplicate delivery idempotent.
- [x] **MP-002 — Accuracy tracking.** The foundation drill records correctness
  and derives an accuracy summary from immutable attempts.
- [x] **MP-003 — Response-time tracking.** Each attempt records response time;
  restarting an interrupted session starts a fresh active timing interval.
- [x] **MP-004 — Attempt and correction tracking.** Answer, correction, retest,
  and hint
  events are immutable, typed, and linked without converting an original error
  or assisted learning into unaided success.
- [ ] **MP-005 — Error taxonomy.** Arithmetic, algebra, concept, assumption,
  notation, method selection, and careless error.
- [x] **MP-006 — Fluency score.** Addition, subtraction, and multiplication derive
  separate recent-evidence scores from correctness and operation-specific speed.
- [ ] **MP-007 — Knowledge mastery score.** Understanding and retained correctness.
  The arithmetic foundation now exposes an explainable derived indicator from
  independent accuracy, fluent evidence, and delayed successful occasions;
  richer concept evidence remains planned.
- [ ] **MP-008 — Performance mastery score.** Solve demanding unfamiliar questions
  accurately under time pressure. The arithmetic foundation now exposes
  accuracy-and-speed performance separately from knowledge; unfamiliar advanced
  problems remain planned.
- [ ] **MP-009 — Technique-selection score.** Identify appropriate tools without
  topic labels.
- [ ] **MP-010 — Confidence calibration score.** Agreement between confidence and
  actual performance.
- [x] **MP-011 — Spaced-repetition scheduler.** Incorrect skills become immediately
  due, slow skills return after five minutes, fluent streaks expand intervals,
  and the review queue prioritises overdue work before approaching reviews.
- [x] **MP-012 — Delayed mastery confirmation.** Three independent successful
  occasions at expanding intervals confirm retention; a later failure records a
  lapse and makes the skill immediately due.
- [x] **MP-013 — Interleaving policy.** The foundation scheduler introduces all
  arithmetic operations, then selects due or weakest skills across the mixture.
- [ ] **MP-014 — Forgetting-risk estimate.** Forecast review need rather than
  treating mastery as permanent. A deterministic arithmetic foundation now
  rises from zero to one across the current review interval and caps when due;
  evidence-calibrated forecasting remains planned.
- [ ] **MP-015 — Session recommendation.** Balance current goal, overdue review,
  fatigue, and available time.
- [x] **MP-016 — Progress dashboard.** Time, independent and assisted attempts,
  accuracy, knowledge, performance, retention, forgetting risk, and curriculum
  goal readiness are derived offline for each foundation skill.
- [x] **MP-017 — Skill history.** Every answer, retest, correction, and hint has a
  chronological learner-facing explanation of whether progress improved,
  reduced, or remained assisted evidence.
- [ ] **MP-018 — Benchmark readiness.** JEE, university, finance, ML, or robotics
  objective coverage and timed-performance estimates.
- [ ] **MP-019 — Streaks without coercion.** Optional consistency information
  without penalising missed days.
- [ ] **MP-020 — Algorithm versioning.** Rebuild derived mastery from events when
  scoring logic changes.

## 6. Lessons, refreshers, and reference library

- [ ] **LR-001 — Seven-minute refresher links.** Curated external videos, with
  timestamped segments where appropriate.
- [ ] **LR-002 — Multiple explanation styles.** Intuitive, geometric, formal, and
  application-oriented alternatives.
- [ ] **LR-003 — One-page concept cards.** Central idea, notation, diagram, worked
  example, common error, and uses.
- [ ] **LR-004 — Formula sheets.** Formula, conditions, units, conventions,
  limiting cases, and related identities.
- [ ] **LR-005 — Worked examples.** Step-by-step examples linked to exact skills.
- [ ] **LR-006 — Common-mistake cards.** Explain why an attractive wrong method or
  result fails.
- [ ] **LR-007 — “When is this useful?” links.** Finance, AI, engineering,
  computing, and robotics applications.
- [ ] **LR-008 — Offline reference library.** Searchable cards, formulas,
  diagrams, examples, and bookmarks.
- [ ] **LR-009 — Mathematical notation glossary.** Symbols disambiguated by field
  and local context.
- [ ] **LR-010 — Dependency-aware navigation.** Jump to prerequisites and return
  to the interrupted lesson.
- [ ] **LR-011 — External-link health checks.** Detect moved or removed resources
  and retain reviewed alternatives.
- [ ] **LR-012 — Personal notes.** Notes attached to concept, question, or formula.
- [ ] **LR-013 — Print/export reference sheets.** Generate compact personal
  revision sheets.
- [ ] **LR-014 — Paper equation decoder.** Expand notation, shapes, assumptions,
  and computational flow.
- [ ] **LR-015 — Citation metadata.** Title, author/provider, URL, reviewed date,
  licence, and why the resource was selected.

## 7. Content-pack platform

- [ ] **CP-001 — Foundation pack bundled with app.** Small offline arithmetic and
  algebra starting set.
- [ ] **CP-002 — Pack manifest parser.** Schema, compatibility, sizes, dependencies,
  digests, and signatures.
- [ ] **CP-003 — Pack compiler.** Convert human-editable source into validated
  distribution form.
- [ ] **CP-004 — Pack validator.** References, IDs, equations, assets, generators,
  licences, and schema.
- [ ] **CP-005 — Signed releases.** Verify publisher signature and SHA-256 before
  activation.
- [ ] **CP-006 — Transactional installation.** Activate only after complete
  validation and retain previous working version.
- [ ] **CP-007 — Selective download.** Install only chosen subjects.
- [ ] **CP-008 — Offline retention controls.** Pin, update, or safely remove packs.
- [ ] **CP-009 — Delta updates.** Avoid downloading unchanged large assets.
- [ ] **CP-010 — Storage forecast.** Display download and installed sizes before
  installation.
- [ ] **CP-011 — Pack catalogue.** Browse level, prerequisites, objectives, status,
  and installed version.
- [ ] **CP-012 — Stable-ID progress retention.** Removing a pack never deletes
  personal history.
- [ ] **CP-013 — Pack rollback.** Restore previous version after validation or
  runtime failure.
- [ ] **CP-014 — Authoring preview.** Render lessons and questions before release.
- [ ] **CP-015 — Content CI.** Schema, link, generator, answer, licence, and
  statistical-distribution tests.

## 8. Local data, sync, and portability

- [x] **DS-001 — Local progress database.** SQLite persists native-platform
  attempts and resumable sessions without network access.
- [x] **DS-002 — Database migrations.** Transactional v1-to-v2 migration preserves
  legacy attempts, assigns explicit legacy metadata, and is forward-tested.
- [ ] **DS-003 — Local content cache.** Independently managed from personal data.
- [ ] **DS-004 — Event merge engine.** Union immutable events instead of replacing
  whole databases.
- [ ] **DS-005 — Idempotent sync.** Duplicate delivery has no effect.
- [ ] **DS-006 — Compact snapshots.** Fast startup while events remain
  authoritative.
- [ ] **DS-007 — Offline outbox.** Queue local events until connectivity returns.
- [ ] **DS-008 — Sync status.** Last success, pending events, provider, and errors.
- [ ] **DS-009 — Conflict policy.** Deterministic handling of mutable preferences
  and notes.
- [ ] **DS-010 — Google Drive app-data sync.** Least-privilege OAuth and isolated
  application folder.
- [ ] **DS-011 — OneDrive app-folder sync.** Least-privilege OAuth and isolated
  application folder.
- [ ] **DS-012 — Dropbox app-folder sync.** Least-privilege OAuth and isolated
  application folder.
- [ ] **DS-013 — One active provider.** Prevent divergent simultaneous cloud
  histories.
- [ ] **DS-014 — Provider migration.** Verified export from one provider and
  import into another.
- [x] **DS-015 — Local-only mode.** The implemented learning loop requires no
  account, cloud provider, AI service, or network access.
- [ ] **DS-016 — Encrypted export.** Portable backup with integrity metadata.
- [ ] **DS-017 — Import preview.** Show identity, versions, counts, and conflicts
  before applying.
- [ ] **DS-018 — Secure token storage.** Platform keystore/keychain-backed OAuth
  credentials.
- [ ] **DS-019 — Data deletion.** Clear local data and optionally remove the app
  cloud folder.
- [ ] **DS-020 — Data transparency.** Explain exactly what is local, synced,
  downloaded, or linked.

## 9. Security, privacy, and optional AI

- [x] **SP-001 — No mandatory AI service.** Foundation question generation,
  integer marking, progress, and resume operate locally.
- [ ] **SP-002 — No behavioural analytics by default.** Explicit opt-in if
  diagnostics are ever added.
- [x] **SP-003 — Secret scanning.** Gitleaks blocks staged secrets before commit,
  scans full history before push, and runs independently in CI.
- [ ] **SP-004 — Least-privilege provider scopes.** App-folder access rather than
  general drive access.
- [ ] **SP-005 — Backup encryption.** Modern authenticated encryption with a
  recovery warning.
- [ ] **SP-006 — Content signature trust store.** Explicit trusted publishers and
  key rotation.
- [ ] **SP-007 — Optional on-device explanations.** Local model only when it adds
  value and the device supports it.
- [ ] **SP-008 — Optional OpenAI key onboarding.** Open official key and billing
  pages, paste/test/replace/delete, secure local storage.
- [ ] **SP-009 — AI cost boundary.** AI remains disabled by default and shows clear
  external-cost implications before activation.
- [ ] **SP-010 — AI answer verification.** Never treat unconstrained model output
  as the mathematical marking authority.
- [ ] **SP-011 — Threat model.** Device compromise, token theft, malicious packs,
  sync replay, and supply-chain risks.
- [ ] **SP-012 — Dependency and licence review.** Record maintenance, platform,
  privacy, and licence implications before adding packages.

## 10. Platform and engineering delivery

- [x] **EN-001 — Automatic CI.** Pushes and pull requests run formatting,
  zero-diagnostic analysis, tests, and coverage only.
- [x] **EN-002 — Diagnostics as errors.** Dart warnings and informational lints
  fail CI.
- [x] **EN-003 — Coverage gate.** Repository line coverage cannot fall below 90%;
  meaningful coverage close to 100% is the engineering objective.
- [x] **EN-004 — Warning-free verified build.** Latest verified full platform run
  completed without compiler or workflow warnings.
- [x] **EN-005 — Manual release workflow.** Full artifacts are built only after an
  explicit confirmed workflow dispatch.
- [x] **EN-006 — Derived semantic versioning.** Owner-controlled `major.minor`
  plus commit-count patch.
- [x] **EN-007 — Version baseline.** `VERSION` declared as `0.1`; its declaration
  commit is `0.1.0`.
- [x] **EN-008 — Immutable-version guard.** Release fails if its tag already
  exists.
- [x] **EN-009 — Draft-first publishing.** Build assets and checksums are attached
  before the GitHub Release is published.
- [x] **EN-010 — Current dependency monitoring.** Dependabot checks pub and GitHub
  Actions ecosystems.
- [ ] **EN-011 — Committed platform runners.** **Planned.** Generate, review, and
  retain platform projects rather than generating them only in CI.
- [ ] **EN-012 — Reproducible dependency lock.** **Planned.** Commit
  `pubspec.lock` for this application.
- [ ] **EN-013 — Android production signing.** Secure release keystore and signed
  APK/AAB.
- [ ] **EN-014 — Apple production signing.** Developer identity, provisioning,
  notarisation, and installable iOS/macOS outputs.
- [ ] **EN-015 — Windows installer signing.** MSIX/installer and trusted code
  signature.
- [ ] **EN-016 — Software bill of materials.** Release dependency inventory.
- [ ] **EN-017 — Build provenance.** Cryptographic artifact attestation where the
  repository plan supports it.
- [ ] **EN-018 — Branch protection.** Require CI and review rules on `main`.
- [ ] **EN-019 — Integration test farm.** Critical journeys on representative
  devices and desktop platforms.
- [ ] **EN-020 — Performance budgets.** Startup, question transition, database,
  download, and memory thresholds.

## 11. Mathematics content modules

- [ ] **MA-001 — Mental arithmetic.** Small-number operations, number bonds,
  multiplication, division, estimation, and timed recall.
- [ ] **MA-002 — Fractions, ratios, percentages, and units.**
- [ ] **MA-003 — Powers, roots, logarithms, scientific notation, and scale.**
- [ ] **MA-004 — Algebraic expansion, factorisation, simplification, and
  rearrangement.**
- [ ] **MA-005 — Equations, systems, inequalities, and approximations.**
- [ ] **MA-006 — Functions, composition, inverses, graphs, and transformations.**
- [ ] **MA-007 — Trigonometry, identities, equations, and geometry.**
- [ ] **MA-008 — Complex numbers and geometric interpretation.**
- [ ] **MA-009 — Sequences, series, combinatorics, and generating functions.**
- [ ] **MA-010 — Limits, continuity, differentiation, and integration.**
- [ ] **MA-011 — Multivariable and vector calculus.**
- [ ] **MA-012 — Taylor and asymptotic methods.**
- [ ] **MA-013 — Linear algebra, geometry, and linear transformations.**
- [ ] **MA-014 — Eigenstructure, projections, least squares, and decompositions.**
- [ ] **MA-015 — Abstract algebra.**
- [ ] **MA-016 — Real and complex analysis.**
- [ ] **MA-017 — Measure theory and functional analysis.**
- [ ] **MA-018 — Probability foundations and conditional probability.**
- [ ] **MA-019 — Random variables, distributions, transforms, and convergence.**
- [ ] **MA-020 — Statistical inference, likelihood, Bayesian methods, and
  experimental design.**
- [ ] **MA-021 — Regression, time series, and econometrics.**
- [ ] **MA-022 — Information theory.**
- [ ] **MA-023 — ODEs, dynamical systems, and stability.**
- [ ] **MA-024 — PDE classification and canonical equations.**
- [ ] **MA-025 — Fourier, Laplace, Green's functions, and spectral methods.**
- [ ] **MA-026 — Numerical linear algebra and conditioning.**
- [ ] **MA-027 — Root finding, interpolation, quadrature, and numerical
  differentiation.**
- [ ] **MA-028 — ODE/PDE numerical solvers, finite differences, and finite
  elements.**
- [ ] **MA-029 — Convex, constrained, nonlinear, and stochastic optimisation.**
- [ ] **MA-030 — Monte Carlo, sampling, and variance reduction.**
- [ ] **MA-031 — Markov chains, martingales, and stochastic processes.**
- [ ] **MA-032 — Brownian motion, Itô calculus, SDEs, and change of measure.**
- [ ] **MA-033 — Discrete mathematics, logic, graph theory, and algorithms.**
- [ ] **MA-034 — Mathematical modelling and dimensional analysis.**
- [ ] **MA-035 — Technique-selection capstones across mathematical domains.**

## 12. School, admissions, and university-standard banks

- [ ] **ED-001 — UK A-level Mathematics coverage.**
- [ ] **ED-002 — UK Further Mathematics coverage.**
- [ ] **ED-003 — JEE Main-style original question bank.** Timed single-answer and
  numerical-answer fluency.
- [ ] **ED-004 — JEE Advanced-style original bank.** Multi-select, numerical, and
  combined-concept problems.
- [ ] **ED-005 — Oxbridge-admissions-style bank.** Original unfamiliar problems
  requiring insight and explanation.
- [ ] **ED-006 — STEP/TMUA-style mathematical problem solving.** Track the
  applicable public syllabi by year without copying protected questions.
- [ ] **ED-007 — Oxbridge undergraduate mathematics standard.** Proof, analysis,
  algebra, probability, applied mathematics, and numerical work.
- [ ] **ED-008 — Oxbridge computing standard.** Algorithms, complexity, logic,
  numerical computing, systems, and theoretical foundations.
- [ ] **ED-009 — University engineering mathematics standard.**
- [ ] **ED-010 — Graduate bridge.** Move from calculation-led courses to proof,
  modelling, numerical experimentation, and paper reading.
- [ ] **ED-011 — Timed benchmark papers.** Original papers with calibrated
  sections, marking rubrics, and post-paper remediation.
- [ ] **ED-012 — Admissions-versus-mastery reporting.** Keep exam performance
  separate from long-term conceptual mastery.

## 13. Quantitative finance content and exam benchmarks

Only mathematical, statistical, modelling, valuation, pricing, portfolio, and
risk content is in scope. Ethics, professional standards, law, regulation,
governance, and rote institutional material are excluded except where a
quantitative model cannot be understood without minimal context.

- [ ] **QF-001 — Financial mathematics.** Discounting, compounding, forwards,
  annuities, yield, duration, convexity, and term structures.
- [ ] **QF-002 — No-arbitrage, replication, state prices, and risk-neutral
  valuation.**
- [ ] **QF-003 — Forwards, futures, swaps, options, and structured payoffs.**
- [ ] **QF-004 — Binomial models and Black–Scholes.**
- [ ] **QF-005 — Greeks, hedging, P&L attribution, and sensitivities.**
- [ ] **QF-006 — Local volatility, stochastic volatility, jumps, and calibration.**
- [ ] **QF-007 — Fixed-income curve construction and interest-rate models.**
- [ ] **QF-008 — Credit, counterparty exposure, default models, and XVA
  foundations.**
- [ ] **QF-009 — Market, credit, liquidity, and model-risk measurement.**
- [ ] **QF-010 — VaR, expected shortfall, stress, backtesting, and scenario
  analysis.**
- [ ] **QF-011 — Portfolio theory, factor models, optimisation, and performance
  attribution.**
- [ ] **QF-012 — Econometrics, volatility, correlation, and financial time
  series.**
- [ ] **QF-013 — Monte Carlo pricing and variance reduction.**
- [ ] **QF-014 — Numerical PDE and transform pricing.**
- [ ] **QF-015 — Market microstructure and quantitative execution.**
- [ ] **QF-016 — Model validation, uncertainty, and inverse problems.**
- [ ] **QF-017 — Machine learning in finance.**
- [ ] **QF-018 — CFA quantitative benchmark mapping.** Quantitative Methods plus
  mathematical parts of derivatives, fixed income, equity valuation, portfolio
  management, and risk; exclude ethics and non-quantitative memorisation.
- [ ] **QF-019 — FRM benchmark mapping.** Quantitative Analysis, Financial Markets
  and Products, Valuation and Risk Models, and quantitative portions of market,
  credit, liquidity, treasury, and investment risk.
- [ ] **QF-020 — PRM benchmark mapping.** Finance theory, instruments, markets,
  Mathematical Foundations of Risk Measurement, and quantitative risk practice;
  exclude standards/governance and operational-process recall.
- [ ] **QF-021 — CQF benchmark mapping.** Mathematical foundations, stochastic
  modelling, derivatives, risk and return, equities/currencies, fixed income,
  credit, data science, and machine learning.
- [ ] **QF-022 — Qualification-style original banks.** CFA/FRM/PRM/CQF-aligned
  coverage and difficulty without reproducing provider questions.
- [ ] **QF-023 — Quant interview bank.** Mental maths, probability, stochastic
  reasoning, estimation, coding, and modelling choices.
- [ ] **QF-024 — Desk problem bank.** Pricing, hedging, calibration, numerical
  stability, data, and production trade-offs.
- [ ] **QF-025 — Finance-paper reading.** Translate notation, assumptions,
  measures, discretisations, and empirical evidence.

Note: **CQA** ordinarily denotes Certified Quality Auditor and is not a
quantitative-finance benchmark. This register assumes the intended qualification
was **CQF — Certificate in Quantitative Finance**.

## 14. Computing content

- [ ] **CS-001 — Data structures and algorithms.**
- [ ] **CS-002 — Complexity, computability, and numerical complexity.**
- [ ] **CS-003 — Floating-point representation, error, and reproducibility.**
- [ ] **CS-004 — Scientific programming and vectorisation.**
- [ ] **CS-005 — Automatic differentiation and computational graphs.**
- [ ] **CS-006 — Parallel, concurrent, distributed, and GPU computation.**
- [ ] **CS-007 — Databases, storage, consistency, and distributed systems.**
- [ ] **CS-008 — Simulation and probabilistic programming.**
- [ ] **CS-009 — Optimiser and solver implementation.**
- [ ] **CS-010 — Algorithm-selection scenarios.**
- [ ] **CS-011 — Code-reading questions.**
- [ ] **CS-012 — Numerical debugging and performance diagnosis.**

## 15. AI, machine learning, deep learning, and LLM content

There is no single vendor-neutral professional examination with the breadth and
mathematical authority that CFA/FRM provide in finance. ReMath therefore uses two
complementary benchmark families:

1. rigorous university-level mathematical and algorithmic curricula;
2. recognised professional certifications for lifecycle, deployment, and systems
   judgement.

- [ ] **AI-001 — Statistical learning foundations.**
- [ ] **AI-002 — Linear models, generalisation, regularisation, and bias–variance.**
- [ ] **AI-003 — Kernels, trees, ensembles, and classical unsupervised learning.**
- [ ] **AI-004 — Bayesian inference, latent-variable models, and graphical
  models.**
- [ ] **AI-005 — Neural-network calculus and backpropagation.**
- [ ] **AI-006 — Optimisation for deep learning.**
- [ ] **AI-007 — Convolutional, recurrent, and sequence models.**
- [ ] **AI-008 — Attention, transformers, embeddings, and positional methods.**
- [ ] **AI-009 — Language-model objectives, tokenisation, scaling, and emergent
  behaviour.**
- [ ] **AI-010 — Fine-tuning, parameter-efficient adaptation, and alignment.**
- [ ] **AI-011 — Retrieval, tools, agents, memory, and evaluation.**
- [ ] **AI-012 — Diffusion, flows, autoregressive, and energy/score models.**
- [ ] **AI-013 — Representation, contrastive, self-supervised, and multimodal
  learning.**
- [ ] **AI-014 — Reinforcement learning and decision processes.**
- [ ] **AI-015 — Uncertainty, calibration, robustness, causality, and experiment
  design.**
- [ ] **AI-016 — Data pipelines, leakage, drift, monitoring, and MLOps.**
- [ ] **AI-017 — Distributed training, GPU kernels, memory, quantisation, and
  inference optimisation.**
- [ ] **AI-018 — Research-paper equation and architecture reading.**
- [ ] **AI-019 — Reproduction and ablation reasoning.**
- [ ] **AI-020 — Method-selection bank.** Match data, constraints, loss, model,
  optimiser, validation, and deployment strategy.
- [ ] **AI-021 — Google Professional ML Engineer benchmark.** Use public exam
  objectives for production ML lifecycle and architecture, while supplementing
  the lighter mathematics.
- [ ] **AI-022 — AWS ML Engineer Associate benchmark.** Data preparation, model
  development, deployment/orchestration, monitoring, maintenance, and security;
  keep cloud-product recall subordinate to transferable reasoning.
- [ ] **AI-023 — NVIDIA Generative AI LLM Associate benchmark.** Foundational LLM
  development, integration, and maintenance.
- [ ] **AI-024 — NVIDIA Generative AI LLM Professional benchmark.** Architecture,
  data, fine-tuning, distributed training, optimisation, inference, deployment,
  evaluation, and reliability.
- [ ] **AI-025 — University-standard ML bank.** Original derivations, proofs,
  calculations, coding analysis, and experiments at rigorous graduate level.
- [ ] **AI-026 — Certification-style practical bank.** Original scenario questions
  mapped to public Google/AWS/NVIDIA objectives.
- [ ] **AI-027 — AI benchmark separation.** Report mathematical depth, research
  literacy, and production certification readiness separately.

## 16. Robotics and physical-AI content

Robotics currently has no single universal CFA-like professional examination.
ReMath will benchmark mathematical depth against strong university robotics,
control, vision, and autonomy curricula, and benchmark practical stack knowledge
against ROS 2 and NVIDIA Physical AI/Isaac learning objectives.

- [ ] **RB-001 — Coordinate frames, homogeneous transforms, rotations, and Lie
  groups.**
- [ ] **RB-002 — Forward and inverse kinematics.**
- [ ] **RB-003 — Jacobians, singularities, manipulability, and differential
  kinematics.**
- [ ] **RB-004 — Rigid-body dynamics and contact.**
- [ ] **RB-005 — Feedback, state-space, stability, and optimal control.**
- [ ] **RB-006 — State estimation, Kalman filtering, particle filtering, and
  sensor fusion.**
- [ ] **RB-007 — Geometry, camera models, vision, and perception.**
- [ ] **RB-008 — Localisation, mapping, and SLAM.**
- [ ] **RB-009 — Search, motion planning, trajectories, and collision avoidance.**
- [ ] **RB-010 — Optimisation-based planning and model predictive control.**
- [ ] **RB-011 — Robot learning, imitation, reinforcement learning, and policies.**
- [ ] **RB-012 — Sim-to-real, domain randomisation, and system identification.**
- [ ] **RB-013 — Multi-robot systems and probabilistic coordination.**
- [ ] **RB-014 — Embedded constraints, latency, real-time systems, and safety.**
- [ ] **RB-015 — ROS 2 concepts.** Nodes, topics, services, actions, transforms,
  timing, QoS, bags, launch, and debugging.
- [ ] **RB-016 — NVIDIA Isaac benchmark.** Isaac Sim, Isaac Lab, Isaac ROS,
  synthetic data, policy training, acceleration, and deployment.
- [ ] **RB-017 — Physical-AI/VLA foundations.** Multimodal perception-language-
  action models and embodied evaluation.
- [ ] **RB-018 — Robotics method-selection bank.** Choose representations,
  estimators, planners, controllers, simulators, and learning approaches.
- [ ] **RB-019 — Robotics paper-reading bank.** Frames, state, observation/action
  spaces, losses, dynamics, metrics, and experimental validity.
- [ ] **RB-020 — Simulation labs.** Future optional interactive numerical
  experiments without requiring physical hardware.
- [ ] **RB-021 — Hardware-linked challenges.** **Later.** Optional experiments
  when a supported robot or sensor is available.
- [ ] **RB-022 — Robotics benchmark separation.** Report mathematical robotics,
  autonomy/AI, ROS competence, and vendor-stack competence separately.

## 17. Source standards for benchmark mappings

These sources define coverage targets only. ReMath content must remain original.

### Finance

- CFA Institute public learning outcomes:
  <https://www.cfainstitute.org/programs/cfa-program/candidate-resources>
- GARP FRM curriculum areas:
  <https://www.garp.org/frm/study-materials>
- PRMIA PRM syllabus and resources:
  <https://prmia.org/Public/Public/PRM/PRM-Resources.aspx>
- CQF programme structure:
  <https://www.cqf.com/about-cqf/program-structure/program-overview>

### AI and ML

- Google Professional Machine Learning Engineer:
  <https://cloud.google.com/learn/certification/machine-learning-engineer>
- AWS Certified Machine Learning Engineer — Associate:
  <https://aws.amazon.com/certification/certified-machine-learning-engineer-associate/>
- NVIDIA certification catalogue:
  <https://www.nvidia.com/en-us/learn/certification/>
- NVIDIA Generative AI LLM Professional:
  <https://www.nvidia.com/en-us/learn/certification/generative-ai-llm-professional/>

### Robotics and physical AI

- NVIDIA Physical AI learning:
  <https://docs.nvidia.com/learning/physical-ai/index.html>
- NVIDIA Isaac:
  <https://developer.nvidia.com/isaac>
- Isaac ROS:
  <https://developer.nvidia.com/isaac/ros>

Public objectives and links must be reviewed periodically because providers
revise curricula and certification versions.
