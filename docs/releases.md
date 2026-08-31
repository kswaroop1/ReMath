# Releases and versioning

ReMath uses Semantic Versioning in the form `major.minor.patch`.

During initial development, versions remain in the `0.y.z` range. The owner
explicitly decides when to change `major.minor`; automation derives `patch`.

## Version calculation

The root `VERSION` file contains only `major.minor`, for example:

```text
0.1
```

The most recent commit that changes `VERSION` is the baseline commit for that
major/minor line and has patch number zero. The release workflow counts commits
after that baseline:

```text
patch = count(commits in VERSION-baseline..release-commit)
```

Examples:

| VERSION | Commits after its declaration | Release |
|---|---:|---:|
| `0.1` | 0 | `0.1.0` |
| `0.1` | 3 | `0.1.3` |
| `0.2` | 0 | `0.2.0` |

Merge commits and commits introduced by a merge are commits and therefore count.
Changing `VERSION` deliberately resets the patch number to zero. Do not edit
`VERSION` for a patch release.

## Creating a release

1. Ensure the intended commit is on the default branch and CI is green.
2. If starting a new major/minor line, change only `VERSION` to the chosen value,
   merge that declaration, and regard that commit as patch zero.
3. Open **Actions → Release → Run workflow**.
4. Select the default branch.
5. Select **Confirm publication of a GitHub Release**.
6. Choose whether GitHub should mark the release as a prerelease.
7. Run the workflow.

The release workflow reruns all quality checks, calculates the version, rejects
an existing version tag, builds every platform, creates SHA-256 checksums, creates
a draft GitHub Release, attaches all assets, and then publishes it.

Each generated release page prepends the verified
[installation guidance](installing.md), including Android sideloading, the
Windows downloaded-file unblock sequence, and the current signing limitations.

Published tags use `vMAJOR.MINOR.PATCH`. A published version is never moved or
replaced; make another release for any changed content.

## Branch policy

Development and releases currently use trunk-based development:

- short-lived topic branches;
- pull requests into protected `main`;
- required CI before merge;
- releases from an exact commit on `main`;
- immutable release tags.

A permanent release branch is unnecessary while only the current line is
supported. Add a maintenance branch such as `release/1.2` only if fixes must be
shipped concurrently for an older line after newer development has moved on.

## Build numbers

The human-facing version is derived as described above. Platform build numbers
use the total reachable commit count, providing a positive, monotonically
increasing integer across major/minor resets.
