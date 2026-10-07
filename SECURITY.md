# Security policy

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability or exposed credential.
Use GitHub's private vulnerability-reporting facility when enabled, or contact
the repository owner privately through the address associated with the GitHub
account.

Include affected versions, reproduction steps, impact, and any suggested
mitigation. Do not include real learner data or active credentials.

## Supported versions

ReMath is pre-release software. Security fixes currently target the latest
commit on `main` and the most recent published release.

## Scope

Particularly sensitive areas include local learner data, backup encryption,
OAuth tokens, content-pack validation/signatures, sync replay, dependency
supply-chain risks, and release signing.

## Secret prevention and response

ReMath uses the Gitleaks open-source scanner at three layers: staged-change
pre-commit checks, full-history pre-push checks, and an independent CI gate.
These controls reduce risk but do not make committed credentials safe.

If a credential reaches Git, especially this public repository:

1. revoke or rotate it immediately;
2. report it privately;
3. assess access and provider audit logs;
4. remove it from the current tree; and
5. decide whether coordinated history rewriting is warranted.

Treat the credential as compromised even if GitHub or Gitleaks later reports the
finding as removed. Do not publish the secret itself in an issue, transcript,
test fixture, scanner artifact, or remediation record.
