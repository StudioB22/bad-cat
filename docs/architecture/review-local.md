# Local review — bad-cat (issue #7 local CI, no GitHub workflow)

Local review gate (`--push` mode) on the local-CI brick: three audits in parallel, the fixes, then
the adversarial verification round.

- Date: 2026-11-10
- Commit: 764d1e9 (branch `ci/7-local-ci-no-workflows`, base `main`)
- Scope: branch diff `main...HEAD` — `justfile`, `lefthook.yml`, `mise.toml`, `mise.lock`,
  `package.json`, `package-lock.json`, `typos.toml`, `scripts/`, `.github/`, ADR-0006,
  `PROJECT_LOG.md`, `README.md`
- Checks run: adversarial (Opus, 2 rounds) · docs (doc-auditor) · tests (test-auditor) ·
  security and secrets (diff read, gitleaks, TruffleHog) · design: not applicable (shell and
  config only)
- Verdict: ship · Must 0 · Should 0 · Nice 4 (open, listed below)

## Adversarial review (#236)

- Round 1 on `b3a8069`: Must 1 · Should 4 · Nice 4 · unverified 1 · Push gate: closed
- Round 2 on `764d1e9`: 9 fixed · 0 not fixed · 0 regressed · new Must 0 · **Push gate: open**
- Optional second review (owner's OpenAI account): not run

## Pre-merge gate (head SHA 764d1e9)

| Step | Result |
| --- | --- |
| 0 CI mirror | n/a after this change (no PR workflow left); the two jobs of the deleted `ci.yml` map to `just secrets` (gitleaks, full history) and `just diagrams` (same script, mermaid-cli 11.4.2 pinned by lockfile) |
| 1 Tests | ✅ `just check`: wiring tests 112 cases + attestation tests 31 cases · 6 Mermaid blocks OK · no unit suite yet (no code) |
| 2 Coverage | not applicable (no code); docs: ⏸ deferred to the pre-merge run |
| 3 SonarQube | ✅ PASSED (local, project `bad-cat`, quality-gate wait) |
| 4 Secrets | ✅ gitleaks clean (`main..HEAD` and full history) · TruffleHog clean · no tracked `.env` · diff read: only fixture tokens and a fake address in the canonical `test-attest.sh` |
| 5 E2E/smoke | not applicable (no running product) |

- Gate: **pre-push green** — `just check` passed (under the 3 min budget), the attestation is
  deferred to `just gate` on the pushed head (`GATE_CI_CHANGE=1`: this branch changes the gate).

## 🔴 Must Have

- Fixed in `764d1e9`: `scripts/toolchain-drift.sh` `[adversarial]` · `nightly` reported the Node
  major as drift from its first run · Node pinned by major, two-pass drift script.
- Fixed: `scripts/systemd/bad-cat-nightly.timer` `[docs|adversarial]` · no install procedure for
  the L3 timer · header with the `systemctl --user` steps; ADR says L3 does not run until then.
- Fixed: `scripts/test-local-ci.sh` `[tests]` · `merge` tests used `origin/main` as the PR head;
  the gate's base fetch was never exercised · PR branch `pr7`, base moved from a second clone.

## 🟡 Should Have

- Fixed: `justfile` gate guard `[adversarial]` · pathspec missed the gitleaks, typos, mise and npm
  files · added, with a per-path test loop.
- Fixed: `scripts/render-mermaid.sh` `[adversarial|security]` · `npx -y` resolved an unpinned
  tree on the machine holding the signing key · `package-lock.json` with integrity hashes,
  `npm ci` in `setup`, `node_modules/.bin/mmdc`.
- Fixed: `.github/dependabot.yml` `[adversarial]` · `github-actions` ecosystem with no workflow ·
  moved to `npm`.
- Fixed: `scripts/test-local-ci.sh` `[tests]` · exit-code-only refusals, binary sonar and mise
  stubs, hooks checked by grep · step text asserted, STARTING / host override / token precedence
  cases, real `lefthook run` of pre-push and commit-msg.
- Fixed: `justfile`, `PROJECT_LOG.md`, `.github/branch-protection.md`, `README.md` `[docs]` ·
  duplicate recipe comments, `test` listed as a tier, time-bound bootstrap paragraph, no
  contributor entry point.

## 🔵 Nice to Have

- `justfile:22-23` `[adversarial]` · `git diff --quiet -- package-lock.json` fails silently and
  leaves the rewritten lockfile · print a message; add a test.
- `scripts/test-local-ci.sh:436` `[adversarial]` · guard loop misses `.mise.toml`,
  `mise.local.toml`, `.typos.toml`, `_typos.toml` · add them to the list.
- `docs/architecture/decisions/0006-run-every-check-locally.md:40,61` `[adversarial]` · two
  unwrapped lines.
- `.github/dependabot.yml` `[adversarial]` · no `cooldown` (brickpix uses `default-days: 3`).

## ⚪ Disagree / Intentional

- `mise.toml` `node = "22"` `[adversarial]` · the skill's exact-pin gotcha is about shim
  resolution; `mise.lock` still installs 22.23.4 and the ADR records the choice.
- `mise.toml` gitleaks 8.30.1 vs the deleted workflow's 8.21.2 `[adversarial]` · rule 8 (same pin)
  applies while a PR CI runs; the workflow is gone and ADR-0006 records the bump.
- Option C over the full docs-only profile `[adversarial]` · owner MCDA in ADR-0006; rule 1 scopes
  the tiers to the real stack.
- `gate` status without `integration_id` `[adversarial]` · the signed note verified by
  `just merge` is the control (ADR-0006 § Consequences).

## Per-dimension summary

- Adversarial: 1 Must (drift) and 4 Should fixed, gate open on round 2 · Design: n/a · Docs:
  systemd install gap filled, justfile noise removed · Tests: two false-confidence cases fixed,
  32 cases added · Security: mermaid-cli tree pinned, no secret in diff or history ·
  Correctness: `just check` green on the fix head.

## Out of scope (follow-ups for skill `local-ci`)

- `lefthook.yml` pre-push checks the checked-out tree, not the pushed refs (template pattern).
- `toolchain-drift.sh` `grep -F mise.toml` would match a parent directory's `mise.toml` path.
