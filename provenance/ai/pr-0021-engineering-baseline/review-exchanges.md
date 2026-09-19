# Review correction exchanges — 19 September 2026

## User

> PR #21, “Establish a reproducible engineering baseline,” is open as a draft on kswaroop1/ReMath. It reconciles the feature register after PR #20 and starts EN-011, EN-012, EN-019, and EN-020, but it has no requested reviewers yet. Help me inspect the current diff and repository state, identify anything still missing for the stated scope, and prepare the concise review checklist or changes needed to make PR #21 ready for independent review.

## Assistant

> PR #21 has moved on: it is no longer a draft, and an explicit `@codex review` request has already produced eight findings against current head `3b6004f`. No individual reviewers are assigned.

> The findings concern release-time runner regeneration, incomplete durable-restoration/startup coverage, in-memory persistence benchmarks, provenance, Dart SDK compatibility, and two performance-harness edge cases.

The assistant offered an audit/checklist or an audit with fixes.

## User

> Audit and implement fixes for the current scope, with tests and updated evidence

## Assistant

> I’ll validate the review findings against the current code, then fix the confirmed issues with test-first commits and updated evidence.

## Retrieved reviewer exchanges (reviewed head 3b6004f)

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843370

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Keep EN-011 open until release jobs use committed runners**

The release artifacts still depend on regenerating every shipped runner immediately before building: `.github/workflows/release.yml:104-105`, `131-132`, `155-156`, and `183-184` invoke `flutter create` after checkout. Consequently, the committed runner sources are neither the sole release inputs nor compiled unchanged by CI, and template generation can mask defects or replace reviewed configuration. Remove those generation steps and build the committed projects, or leave EN-011 incomplete.

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843372

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Drive the journey through the production bootstrap**

This test manually creates an in-memory database and retains the same repository and content-pack objects across a widget unmount, so it never executes `main()`, `openProgressRepository()`, the application-support-directory boundary, or a close-and-reopen cycle. A broken native bootstrap or failure to persist across a real interruption would therefore pass while EN-019 is described as production-composed durable restoration; exercise a shared production bootstrap against temporary durable storage instead.

AGENTS.md reference: [AGENTS.md:L130-L133](https://github.com/kswaroop1/ReMath/blob/3b6004feac4cf7cd72b3ac7d72dcd1952fcf07dc/AGENTS.md#L130-L133)

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843376

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Measure startup through the production bootstrap**

The operation called `application startup` begins after the content pack is loaded and substitutes `SqliteProgressRepository(sqlite3.openInMemory())` for the production `openProgressRepository()` path. Regressions in asset bootstrap, path-provider initialization, directory creation, or opening and migrating the real database cannot affect this threshold, so it does not enforce the advertised production startup budget.

AGENTS.md reference: [AGENTS.md:L130-L133](https://github.com/kswaroop1/ReMath/blob/3b6004feac4cf7cd72b3ac7d72dcd1952fcf07dc/AGENTS.md#L130-L133)

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843381

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Benchmark persistence on a durable SQLite file**

All persistence samples target `sqlite3.openInMemory()`, which omits filesystem writes, journaling, synchronization, and platform storage behavior. A severe regression in the native on-disk attempt path would leave this 100 ms budget green, so use a temporary SQLite file through the real storage boundary or explicitly scope the budget to in-memory repository overhead.

AGENTS.md reference: [AGENTS.md:L130-L133](https://github.com/kswaroop1/ReMath/blob/3b6004feac4cf7cd72b3ac7d72dcd1952fcf07dc/AGENTS.md#L130-L133)

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843385

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Preserve attributable AI exchanges in provenance**

The provenance is an undifferentiated third-person narrative rather than role-attributed chronological entries, and it paraphrases the user prompts and material agent responses despite declaring no redactions. This conflicts with `provenance/ai/README.md:41-45`, prevents reviewers from comparing the actual instructions and responses with the diff and history, and leaves the record insufficient as substantive evidence; add the available user/agent/reviewer/CI exchanges or explicit justified omissions.

AGENTS.md reference: [AGENTS.md:L90-L102](https://github.com/kswaroop1/ReMath/blob/3b6004feac4cf7cd72b3ac7d72dcd1952fcf07dc/AGENTS.md#L90-L102)

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843387

**<sub><sub>![P1 Badge](https://img.shields.io/badge/P1-orange?style=flat)</sub></sub>  Align the lockfile with the declared Dart SDK floor**

The committed lock requires Dart `>=3.11.0`, while `pubspec.yaml:6-7` declares the application compatible with Dart `>=3.10.0`. On a Dart 3.10 toolchain that satisfies the manifest, the committed resolution cannot be used and dependency installation must fail or replace it, defeating the promised portable lock boundary. Raise the manifest floor to 3.11 or regenerate a resolution that supports the declared 3.10 floor.

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843392

**<sub><sub>![P2 Badge](https://img.shields.io/badge/P2-yellow?style=flat)</sub></sub>  Reject negative warm-up counts**

The constructor validates `sampleRuns` but accepts a negative `warmUpRuns`; the loop condition then silently executes zero warm-ups rather than the declared count. Any caller deriving this value from configuration can therefore receive apparently valid measurements under a different sampling policy, so reject negative counts and cover that invalid-input path.

AGENTS.md reference: [AGENTS.md:L130-L133](https://github.com/kswaroop1/ReMath/blob/3b6004feac4cf7cd72b3ac7d72dcd1952fcf07dc/AGENTS.md#L130-L133)

Useful? React with 👍 / 👎.

### Reviewer — https://github.com/kswaroop1/ReMath/pull/21#discussion_r4052843394

**<sub><sub>![P2 Badge](https://img.shields.io/badge/P2-yellow?style=flat)</sub></sub>  Preserve sub-millisecond values in budget failures**

Both durations are truncated with `inMilliseconds`, so a median of 100.5 ms against a 100 ms limit fails while reporting `100ms exceeded allowed 100ms`. This can occur with the current millisecond thresholds because `Stopwatch` records finer-grained durations, producing a contradictory diagnostic precisely when a near-boundary failure needs investigation; format the full duration or include microseconds.

Useful? React with 👍 / 👎.

