# PR #33 — Dependency lock reproducibility

## 2026-11-16 — CI evidence

[Run 43980039113](https://github.com/kswaroop1/ReMath/actions/runs/43980039113) passed historical red replay after rebasing #31, then failed `git diff --exit-code -- pubspec.lock`. Flutter 3.50.0 rewrote the Dart SDK floor from `>=3.11.0` to `>=3.13.0-0`; no resolved package changed in that diff.

## 2026-11-18 — Post-merge inspection

PR #31 merged at `990d737` with the failing lockfile blob unchanged. No successful post-merge run was verified.

## 2026-11-21 — User

> Ok do that. And fix. And i do think we have reached a point where a real release with binaries for windows and android at leasr should be created

## 2026-11-21 — Codex

Used the exact one-line lockfile output from the failing run. GitHub returned blob `4f07b43`, matching the CI diff's regenerated blob prefix. The existing unchanged-lockfile check supplies regression evidence; no new business behaviour or test assertion is introduced. Opened draft PR #33 for full CI and independent review. No merge, VERSION edit, release publication, or signing change in this PR. Release remains a separate manual workflow on green main.
