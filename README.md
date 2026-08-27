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

This repository contains the initial Flutter foundation. The first milestone is
the learning-session shell, deterministic question generation, local progress
events, and tests. Cloud synchronisation and downloadable course packs are
deliberately separated behind interfaces so providers can be added without
changing the learning engine.

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
