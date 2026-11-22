# PR #33 — Dependency lock reproducibility

## 2026-11-16 — CI evidence

[Run 43980039113](https://github.com/kswaroop1/ReMath/actions/runs/43980039113) passed historical red replay after rebasing #31, then failed `git diff --exit-code -- pubspec.lock`. Flutter 3.50.0 rewrote the Dart SDK floor from `>=3.11.0` to `>=3.13.0-0`; no resolved package changed in that diff.

## 2026-11-18 — Post-merge inspection

PR #31 merged at `990d737` with the failing lockfile blob unchanged. No successful post-merge run was verified.

## 2026-11-21 — User

> Ok do that. And fix. And i do think we have reached a point where a real release with binaries for windows and android at leasr should be created

## 2026-11-21 — Codex

Used the exact one-line lockfile output from the failing run. GitHub returned blob `4f07b43`, matching the CI diff's regenerated blob prefix. The existing unchanged-lockfile check supplies regression evidence; no new business behaviour or test assertion is introduced. Opened draft PR #33 for full CI and independent review. No merge, VERSION edit, release publication, or signing change in this PR. Release remains a separate manual workflow on green main.

## 2026-11-22 — Flutter compatibility follow-up

Run [44953869697](https://github.com/kswaroop1/ReMath/actions/runs/44953869697) passed the lock check and 587 native tests but failed fatal analysis on 18 deprecated Material imports. User authorized continuing: “Ok go ahead”. Follow Flutter’s [official migration](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui): replace the imports and use the Flutter-published BSD-3-Clause Material package, supported on Android, iOS, Linux, macOS, web and Windows. It is a UI-only library, does not need learner data or network access, and remains outside domain code. Keep warning policy and test assertions unchanged. CI must resolve and verify the lock and run the full suite before release.

## 2026-11-22 — CI follow-up

User: “Please fix these all and let me know when done”. [Run 45005037575](https://github.com/kswaroop1/ReMath/actions/runs/45005037575) generated a lockfile diff and observed exit 255 in the concurrent publisher-trust command test (586 passed). Applied the generated diff to the exact merge-candidate lockfile, retaining the merged file_picker update. Added stderr to unchanged concurrent process assertions; the previous log cannot distinguish process startup failure from a SQLite error. No production change or claim of a confirmed race fix at this checkpoint.

## 2026-11-22 — Import-order correction

User asked for clues on the failure. [Run 45055547255](https://github.com/kswaroop1/ReMath/actions/runs/45055547255) passed lock verification and all 587 native tests, including the concurrent process case; exit 255 did not recur. Fatal analysis reported 11 import-order diagnostics after the Material migration. Sorted only the affected imports; no lint or test assertion was changed. The intermittent exit remains unexplained.
