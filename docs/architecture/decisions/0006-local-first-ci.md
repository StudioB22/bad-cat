# ADR-0006: Run every check locally, no GitHub workflow

Every quality and security check of bad-cat runs on the developer's machine and in git hooks; the repository keeps no GitHub Actions workflow at all.

- Status: Accepted (owner, 2026-11-10)
- Issue: #7

## Context

The owner decided on 2026-11-07 that on every project all checks run locally and GitHub Actions
is reserved for a production deploy triggered by a signed release tag (skill `local-ci`;
agents-skills ADR-0003 attestation, ADR-0004 prod from signed tags, epic
benoit-bremaud/agents-skills#259). GitHub Actions minutes now bill the account.

bad-cat ran one workflow, `ci.yml` (PR #4): gitleaks on the full history through the CLI image,
and `scripts/render-mermaid.sh` on every Markdown file. SonarQube already ran locally (the
GitHub runner could not reach `localhost:9000`). Nothing deploys from GitHub: the product runs on
a Raspberry Pi (ADR-0005, `08-deployment.md`), installed by hand.

Reference implementations merged the same week: benoit-bremaud/retro-shmup#158 (no workflow)
and benoit-bremaud/brickpix#55 (`prod.yml` kept for a Cloudflare Worker).

## Decision drivers

Weights: conformance to the 2026-11-07 rule and the skill 30, simplicity (KISS, one tool per real
check) 30, defects actually caught 20, cost and false positives 20.

## Options (MCDA)

The scope of the local checks for a docs-only repository (Markdown plus one shell script):

| Option | Conformance | Simplicity | Defects caught | Cost | Total /500 |
| --- | --- | --- | --- | --- | --- |
| C. Mirror of `ci.yml` + shellcheck + typos | 5 | 4 | 4 | 5 | **450** |
| A. Mirror of `ci.yml` + shellcheck | 4 | 5 | 3 | 5 | 430 |
| B. Full docs-only profile (C + markdownlint-cli2 + lychee) | 5 | 3 | 5 | 2 | 380 |

Sensitivity: simplicity at 45 and conformance at 15 → A leads (445 vs 435); C stays first
otherwise. Whether to keep a workflow was not scored: nothing deploys, so the rule leaves none.

## Decision

Option C, with zero workflow:

| Check | Was | Is now |
| --- | --- | --- |
| secrets | `ci.yml` job `secrets`: gitleaks CLI image 8.21.2, full history | gitleaks 8.30.1 (mise): `--staged` on pre-commit, full history in `just secrets` |
| Mermaid render | `ci.yml` job `diagrams`: `scripts/render-mermaid.sh .`, mermaid-cli 11.4.2, Node 22 | `just diagrams`, same script and pin, Node 22.23.4 from mise |
| shell scripts, hooks, spelling | none | `just lint`: shellcheck on `scripts/*.sh`, `lefthook validate`, typos (`typos.toml`) |
| local CI wiring | none | `just test`: `scripts/test-local-ci.sh`, `scripts/test-attest.sh` |
| SonarQube quality gate | manual `sonar-scanner` before merge | `just sonar` in `gate`, quality-gate wait (#159: never skipped) |
| merge | GitHub button after green Actions | `just merge <pr>` only, after `just gate` on the pushed head; the `main` ruleset requires the `gate` status alone (`.github/branch-protection.md`) |

The tiers (`justfile`): L0 `just fast` on pre-commit (staged secrets, typos, shellcheck), L1
`just check` on pre-push (lint, test, diagrams, secrets; 56 s measured), L2 `just gate` before
every merge (check, Sonar, then the attestation), L3 `just nightly` on a systemd user timer
(check, TruffleHog, toolchain drift). Tools are pinned in `mise.toml` and `mise.lock`; `just setup`
installs them and the hooks. Dependabot stays (its `github-actions` ecosystem has nothing to
track until a workflow returns). `scripts/attest.sh`, `test-attest.sh`, `check-cassettes.sh` and
`check-commit-msg.sh` are verbatim copies of `~/.claude/scripts` (agents-skills#400: no drift
between copies; `check-cassettes.sh` is there only because `test-attest.sh` exercises it).

## Consequences

- No check runs on GitHub: a pull request shows the `gate` status only, posted by
  `scripts/attest.sh` after the signed note. The signed note, verified against
  `.github/allowed_signers` of `origin/main`, is the real control; the status alone is a plain
  API write.
- Bootstrap: this change edits the gate itself, so its gate runs with `GATE_CI_CHANGE=1` after a
  human read of the files, and it is merged with `gh pr merge --squash` under the owner's waiver
  (`.github/allowed_signers` is not on `main` before it, so `just merge` cannot verify the note).
  Every later merge goes through `just merge <pr>`.
- A squash merge creates a `main` commit with no attestation: the next brick's gate runs on its
  own pushed head, which contains it.
- Lefthook needs the hooks installed once per clone: `just setup`. Clément's clone too.
- With the first code brick, `just test` gains the unit tests with coverage ≥ 80 % and `check`
  gains Semgrep CE (skill `local-ci` rule 1).
