# Local CI (#7, skill local-ci, ADR-0006): four tiers, one recipe each, no GitHub and no AI agent
# needed. bad-cat deploys nothing from GitHub, so no workflow is left at all (agents-skills
# ADR-0004). Tools come from mise.toml (`just setup`); run through `mise x -- just <tier>` when
# the shell does not activate mise (the git hooks do).
#
#   L0 fast     pre-commit hook                        staged files only                     < 10 s
#   L1 check    pre-push hook, review-local --push     lint + test + diagrams + secrets      < 3 min
#   L2 gate     review-local § 2b, on the pushed head  check + Sonar, then the attestation   5–15 min
#               before every merge
#   L3 nightly  systemd user timer                     check + TruffleHog + toolchain drift
#
# Then: `just merge <pr>` (refuses without the gate attestation on the head SHA). Code checks
# (unit tests, coverage, Semgrep) join `check` with the first code brick.

set shell := ["sh", "-eu", "-c"]

# L1 by default
default: check

# Once per clone: the pinned toolchain and the git hooks
setup:
    mise install
    mise x -- lefthook install

# L0 — the pre-commit checks on the staged files (< 10 s)
fast:
    lefthook run pre-commit

# The shell scripts, the hook config, spelling (typos.toml)
lint:
    shellcheck --severity=warning scripts/*.sh
    lefthook validate
    typos

# The wiring of this local CI and of the attestation (skill local-ci rule 7); the project's own
# tests join here with the first code brick
test:
    sh scripts/test-local-ci.sh
    sh scripts/test-attest.sh

# Every Mermaid block of the repository renders (mermaid-cli pinned in scripts/render-mermaid.sh;
# replaces the `diagrams` job of the former ci.yml)
diagrams:
    sh scripts/render-mermaid.sh .

# Secrets in the whole git history (replaces the `secrets` job of the former ci.yml)
secrets:
    gitleaks git --redact --no-banner .

# L1 — pre-push (< 3 min)
check: lint test diagrams secrets

# L2 — pre-merge, called by review-local § 2b (base: the branch to integrate into), 5–15 min.
# Ends with the gate attestation (agents-skills ADR-0003): commit status `gate` + signed note on
# HEAD, which must already be pushed and up to date with `base`, so it runs on the pushed head only.
# L2 — pre-merge on the pushed head: check + Sonar, then the attestation
gate base="origin/main":
    #!/bin/sh
    set -eu
    base={{quote(base)}}
    [ -z "$(git status --porcelain)" ] || { echo "gate: commit or set aside local changes first" >&2; exit 1; }
    case "$base" in origin/*) git fetch --quiet origin "${base#origin/}" ;; esac
    git merge-base --is-ancestor "$base" HEAD || { echo "gate: HEAD is behind $base, merge or rebase it first" >&2; exit 1; }
    # Reminder, not a control (this justfile is the branch's own): read a branch's CI changes before
    # gating it with the owner's keys and tokens, then GATE_CI_CHANGE=1 just gate.
    ci=$(git diff --name-only "$base...HEAD" -- justfile lefthook.yml mise.toml mise.lock typos.toml scripts .github sonar-project.properties)
    [ -z "$ci" ] || [ "${GATE_CI_CHANGE:-0}" = 1 ] || { echo "gate: this branch changes the local CI itself ($(printf '%s' "$ci" | tr '\n' ' ')): read those files, then run GATE_CI_CHANGE=1 just gate" >&2; exit 1; }
    [ -n "$(git branch -r --contains HEAD)" ] || { echo "gate: push HEAD first (the attestation is written on the pushed head)" >&2; exit 1; }
    # `check` runs from the body, not as a dependency, so the HEAD it checked is the one attested.
    start=$(git rev-parse HEAD)
    just check
    just sonar
    [ "$(git rev-parse HEAD)" = "$start" ] || { echo "gate: HEAD moved during the gate ($start checked), run it again" >&2; exit 1; }
    sh scripts/attest.sh write gate "$start"

# SonarQube analysis on the local Community Build (sonar-project.properties) with the token of
# ~/.config/sonar-tokens/bad-cat (fallback: the global analysis token
# ~/.config/sonarqube/analysis-token, skill infra-accounts), waiting for the quality gate.
# SonarQube analysis with quality-gate wait (step of gate)
sonar:
    #!/bin/sh
    set -eu
    command -v sonar-scanner > /dev/null || { echo "sonar: sonar-scanner not on PATH (system tool, skill local-ci rule 2)" >&2; exit 1; }
    SONAR_TOKEN="${SONAR_TOKEN:-$(cat "$HOME/.config/sonar-tokens/bad-cat" 2>/dev/null || cat "$HOME/.config/sonarqube/analysis-token" 2>/dev/null || true)}"
    [ -n "$SONAR_TOKEN" ] || { echo "sonar: no token in SONAR_TOKEN, ~/.config/sonar-tokens/bad-cat or ~/.config/sonarqube/analysis-token" >&2; exit 1; }
    url="${SONAR_HOST_URL:-http://localhost:9000}"
    curl -sf -m 5 "$url/api/system/status" | grep -q '"status":"UP"' || { echo "sonar: SonarQube is not UP at $url, start it first" >&2; exit 1; }
    SONAR_TOKEN="$SONAR_TOKEN" sonar-scanner -Dsonar.host.url="$url" -Dsonar.qualitygate.wait=true

# Merge a PR only when its exact head SHA carries the gate attestation (agents-skills ADR-0003).
# The verifier is read from origin/main. Squash, as every merge of this repository. Same-repository
# PRs only (the head is fetched from origin).
merge pr:
    #!/bin/sh
    set -eu
    pr={{quote(pr)}}
    case "$pr" in ''|*[!0-9]*) echo "merge: usage just merge <pr number>" >&2; exit 1 ;; esac
    sha=$(gh pr view "$pr" --json headRefOid -q .headRefOid)
    git fetch --quiet origin main "$sha"
    # The verifier of origin/main, never the checkout's: a branch cannot ship its own.
    verifier=$(mktemp); trap 'rm -f "$verifier"' EXIT
    git show origin/main:scripts/attest.sh > "$verifier"
    sh "$verifier" verify gate "$sha"
    gh pr merge "$pr" --squash --match-head-commit "$sha"

# L3 — nightly, systemd user timer (no time budget): deep secret history (TruffleHog, offline) and
# toolchain drift: scripts/toolchain-drift.sh fails on a mise.toml tool behind its latest release.
# L3 — nightly (systemd timer): check + TruffleHog + toolchain drift
nightly: check
    trufflehog git "file://$PWD" --no-verification --fail --no-update
    sh scripts/toolchain-drift.sh
