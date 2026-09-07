# PR 11 AI-assisted development transcript

This chronological record contains the PR-related human prompts and material
agent responses available to the contributor. Hidden system/developer
instructions, internal reasoning, credentials, and unrelated context are
excluded under repository policy.

## Selection and observed installation

### User

> i merged it. should we create a release now - that we can actually install on
> android and also run on windows

The owner manually triggered the confirmed release workflow. ReMath 0.1.11 was
published from the merged main commit with Android and Windows assets.

### User

> i extracted C:\Users\kswaroop\Downloads\remath-0.1.11-windows - doesn't do
> anything

Codex verified that the ZIP contained the executable, Flutter engine, SQLite,
assets, and native dependencies. The owner demonstrated that the executable ran
from PowerShell. Clearing Windows' downloaded-file marker with `Unblock-File`
then made ordinary Explorer double-click launch work.

### User

> after that unblockfile - simply double clicking worked

### Assistant

Codex identified the need to put this verified instruction in future release
documentation and noted that trusted Windows code signing remains separate.

### User

> Continue

Codex selected a bounded release-hardening change: publish verified Android and
Windows installation instructions automatically, while documenting rather than
overstating the incomplete Android and Windows production-signing features.

## Acceptance criteria

- Future release pages contain the verified Windows unblock instructions.
- Repository documentation explains Android sideloading and Windows extraction.
- Current signing limitations are explicit and do not claim upgrade-stable or
  trusted production packages.
- The release publication contract is checked in ordinary CI.

## TDD record

### Release installation publication — red

Codex first added a repository contract requiring the verified `Unblock-File`
recovery, preferred pre-extraction unblock sequence, explicit Android
upgrade-signing limitation, Windows code-signing boundary, and automatic
publication of that guidance in generated GitHub release notes. The expected
installation document and workflow integration do not yet exist.

CI run 33361477036 failed the new test because `docs/installing.md` did not
exist, confirming the intended missing publication contract.

### Release installation publication — green

Codex added the verified Android and Windows instructions, including the
pre-extraction Windows unblock sequence and the PowerShell recovery that the
owner demonstrated. The guide explicitly separates portable artifacts from
production signing and warns that current Android prereleases are not
upgrade-stable. The release publisher now checks out the repository and prepends
this guide to GitHub-generated notes for every future release.
