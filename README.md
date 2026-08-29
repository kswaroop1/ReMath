# ReMath

ReMath is an offline-first, cross-platform mathematical fluency and intuition
trainer. It begins with speed arithmetic and grows through A-level/Further
Maths, JEE-style problem solving, university mathematics, quantitative finance,
computing, and AI/ML mathematics.

The fundamental learning unit is a resumable **15-minute chunk**. ReMath trains
three separate capabilities:

1. fluency — accurate, fast manipulation;
2. understanding — conceptual and visual comprehension;
3. technique selection — recognising which mathematical tool fits a problem.

## Status

The implemented foundation includes deterministic arithmetic generation, exact
local marking, immutable progress events, adaptive fluency scheduling, resumable
15-minute drills, and an offline arithmetic diagnostic with independent,
explainable placement for addition, subtraction, and multiplication. Incorrect
drill answers now require a persisted correction and same-skill retest, while
repeated errors produce an offline prerequisite-review suggestion. The same
recommendation can now open an offline concept card with a resumable
four-level hint ladder; assistance remains separate from unaided mastery. A
validated schema-v3 curriculum graph now explains readiness, recommends unmet
prerequisites without blocking exploration, and maps foundation skills to JEE,
quant-finance, and AI-mathematics goals through an offline curriculum browser.
Delayed-retention evidence now distinguishes immediate repetition from recall on
separate occasions, records lapses, and offers resumable review chunks for
overdue or approaching skills. An offline progress dashboard separates
knowledge, performance, accuracy, assistance, retention, forgetting risk, and
goal readiness, with per-skill history explaining how every event affected the
displayed state. Cloud synchronisation and downloadable course
packs remain deliberately separated behind interfaces so providers can be added
without changing the learning engine.

## Platforms

- Android
- iOS/iPadOS
- Windows
- macOS
- Web may be enabled later, but is not a primary offline target yet.

## Getting started

Install a current stable Flutter SDK, then run:

```bash
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
flutter run
```

Platform runner directories are generated with:

```bash
flutter create --platforms=android,ios,windows,macos .
```

Run that command only with a compatible Flutter stable release and review its
generated changes before committing them.

## Documentation

- [Architecture](docs/architecture.md)
- [ADR 0001: local progress persistence](docs/adr/0001-local-progress-persistence.md)
- [ADR 0002: adaptive fluency scheduling](docs/adr/0002-adaptive-fluency-scheduling.md)
- [Numbered feature register](docs/features.md)
- [Delivery roadmap](docs/roadmap.md)
- [Testing strategy](docs/testing.md)
- [Releases and versioning](docs/releases.md)
- [Content-pack format](docs/content-packs.md)
- [Contribution and agent guidance](AGENTS.md)

## Principles

- The core learning experience must work without internet or paid AI.
- Local storage is authoritative for immediate use; sync is optional.
- Progress data and standard curriculum content have separate lifecycles.
- Generated questions are deterministic and reproducible from template version
  plus seed.
- Curated problems must be original or properly licensed.
- Accessibility and keyboard operation are first-class requirements.
