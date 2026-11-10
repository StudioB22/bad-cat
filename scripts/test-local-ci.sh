#!/bin/sh
# Tests for the local CI wiring (#7, skill local-ci rule 7): the tiers compose as the justfile
# says, no GitHub workflow is left (ADR-0006), the hooks are wired, the commit-msg subjects; then
# the gate, merge, sonar and drift recipes in a throwaway repository with stubbed boundaries (just
# steps, attest.sh, gh, sonar-scanner, curl, mise), each case commented in place; last the real L0
# hooks. Needs mise, just, lefthook, gitleaks, shellcheck, typos (the tool wordings asserted are
# pinned by mise.lock):
#   mise x -- sh scripts/test-local-ci.sh
set -e
# A hook (pre-push runs `just check`) exports these; they would aim git at the outer repository.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_OBJECT_DIRECTORY GIT_COMMON_DIR
# The gate of a branch that changes the local CI runs with GATE_CI_CHANGE=1; the guard cases
# below must not inherit it.
unset GATE_CI_CHANGE
# A developer shell may export the SonarQube token or host: the sonar cases below set their own.
unset SONAR_TOKEN SONAR_HOST_URL
# The throwaway repositories must not inherit the machine's signing, hooks or URL rewrites.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
# The L0 hooks run `mise x --` in the throwaway repo, which records a trust entry for its path: drop it.
trap 'rm -f "${MISE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/mise}"/trusted-configs/*"$(basename "$work")"*; rm -rf "$work"' EXIT
n=0
fail() { echo "FAIL $1"; exit 1; }
ok() { n=$((n + 1)); }

# `mise x --` puts the tools on PATH but not mise itself (hooks and the throwaway repo need it).
command -v mise > /dev/null || { [ -x "$HOME/.local/bin/mise" ] && PATH="$HOME/.local/bin:$PATH" && export PATH || true; }
for bin in mise just lefthook gitleaks shellcheck typos; do
  command -v "$bin" > /dev/null || fail "$bin not on PATH"
done

# Tiers and their composition.
cd "$root"
for r in fast setup; do # the others run below or inside check
  just --show "$r" > /dev/null 2>&1 || fail "recipe $r missing"; ok
done
deps() { just --show "$1" | grep -E "^$1( |:)" | sed 's/.*: *//'; } # deps <recipe>
[ "$(deps check)" = "lint test diagrams secrets" ] || fail "check must be exactly lint test diagrams secrets"; ok
deps nightly | grep -qw check || fail "nightly does not depend on check"; ok
# Regression guards against narrowing the scans.
just --show diagrams | grep -q 'scripts/render-mermaid.sh \.' || fail "diagrams does not render the whole repository"; ok
just --show secrets | grep -q 'gitleaks git --redact' || fail "secrets does not scan the history with gitleaks"; ok
# No GitHub workflow at all (ADR-0006): nothing deploys from GitHub.
[ ! -d .github/workflows ] || fail "a GitHub workflow is left (ADR-0006)"; ok
grep -qE '^ +mise x -- just check$' lefthook.yml || fail "pre-push hook does not run just check"; ok
lefthook validate > /dev/null || fail "lefthook validate"; ok

# commit-msg subjects.
msg() { # msg <expected-exit> <subject>
  printf '%s\n' "$2" > "$work/msg"
  rc=0; sh scripts/check-commit-msg.sh "$work/msg" > /dev/null 2>&1 || rc=$?
  [ "$rc" -eq "$1" ] || fail "commit-msg '$2': exit $rc, expected $1"; ok
}
msg 0 'ci(workflows): move every check to local CI'
msg 0 'feat: no scope'
msg 0 'feat(detector)!: the chain breaks on a miss'
msg 0 'Merge branch main into feat/1'
msg 0 'fixup! feat: x'
msg 1 'Wire just'
msg 1 'ci(workflows): ends with a period.'
msg 1 'wip(workflows): not a listed type'
msg 0 "feat(detector): $(printf 'x%.0s' $(seq 84))" # exactly 100 characters
msg 1 "feat(detector): $(printf 'x%.0s' $(seq 85))" # 101
msg 1 ''
msg 0 'Revert "feat: x"'
msg 1 'feat(Detector): uppercase scope'
msg 0 'amend! feat: x'
msg 0 'squash! feat: x'
msg 1 'feat:  two spaces'

# Recipes with their boundaries stubbed, in a throwaway repository with a bare origin. The real
# `just` runs the recipe; a stub `just` first on PATH records the steps the recipe delegates to
# (check, sonar) and fails the one named in FAIL_STEP; stub attest.sh, gh, sonar-scanner, curl and
# mise log their arguments. Every refusal must leave no "attest write" / "gh pr merge" /
# "sonar-scanner" line.
real_just=$(command -v just)
box="$work/box"; mkdir -p "$box/origin" "$box/stub"
git -C "$box/origin" init -q --bare -b main
git clone -q "$box/origin" "$box/repo" 2> /dev/null; cd "$box/repo"
git config user.email t@example.com && git config user.name t
cp "$root/justfile" "$root/mise.toml" "$root/mise.lock" . && mkdir -p scripts docs
cat > scripts/attest.sh <<'EOF2'
#!/bin/sh
echo "attest $*" >> "$LOG"; [ "${ATTEST_FAIL:-0}" = 0 ]
EOF2
cat > "$box/stub/just" <<'EOF2'
#!/bin/sh
echo "just $*" >> "$LOG"
[ "${FAIL_STEP:-}" != "$1" ] || exit 1
[ "$1" != sonar ] || [ -z "${MOVE_HEAD:-}" ] || git commit -q --allow-empty -m 'chore: moved' --no-verify
EOF2
cat > "$box/stub/gh" <<'EOF2'
#!/bin/sh
echo "gh $*" >> "$LOG"; [ "${GH_FAIL:-}" != "$2" ] || exit 1
case "$*" in "pr view"*) git rev-parse origin/pr7 ;; esac # the PR head: a real, fetchable commit, not origin/main
EOF2
cat > "$box/stub/sonar-scanner" <<'EOF2'
#!/bin/sh
echo "sonar-scanner $* token=${SONAR_TOKEN:-none}" >> "$LOG"; echo "sonar-scanner $*"; [ "${SCANNER_FAIL:-0}" = 0 ]
EOF2
cat > "$box/stub/mise" <<'EOF2'
#!/bin/sh
echo "mise $*" >> "$LOG"
case "$*" in *--bump*) printf '%s\n' "$MISE_OUT" ;; *) printf '%s\n' "${MISE_PATCH:-}" ;; esac
EOF2
cat > "$box/stub/curl" <<'EOF2'
#!/bin/sh
echo "curl $*" >> "$LOG"; [ "${SONAR_DOWN:-0}" = 0 ] && echo "{\"status\":\"${SONAR_STATUS:-UP}\"}"
EOF2
chmod +x scripts/attest.sh "$box/stub"/*
export MISE_TRUSTED_CONFIG_PATHS="$box/repo" LOG="$work/log"
git add -A && git commit -qm 'chore: init' --no-verify && git push -q origin main 2> /dev/null
# The PR branch merge works on: its tip must differ from origin/main.
git checkout -q -b pr7 && git commit -q --allow-empty -m 'feat: pr7' --no-verify && git push -q origin pr7 2> /dev/null && git checkout -q main
fresh() { git reset -q --hard origin/main && git clean -fdq; } # every block starts from origin/main
box_run() { # box_run <expected-exit> <label> <text the output or log must hold|-> -- <env>… <just args>
  want=$1 label=$2 text=$3; shift 4
  : > "$LOG"; rc=0; env PATH="$box/stub:$PATH" "$@" > "$work/out" 2>&1 || rc=$?
  [ "$rc" -eq "$want" ] || { cat "$work/out" "$LOG"; fail "$label: exit $rc, expected $want"; }
  [ "$text" = - ] || grep -qF -- "$text" "$work/out" "$LOG" || { cat "$work/out" "$LOG"; fail "$label: output lacks '$text'"; }
  ok
}
no_line() { ! grep -q "$1" "$LOG" || { cat "$LOG"; fail "$2"; }; ok; }

# gate: refusals first, then the order of the steps, then the two late refusals.
echo dirty > docs/d && box_run 1 "gate: dirty tree refused" "commit or set aside" -- "$real_just" gate main
no_line '^just check' "gate ran check on a dirty tree"; rm docs/d
git commit -q --allow-empty -m 'chore: unpushed' --no-verify
box_run 1 "gate: unpushed HEAD refused" "push HEAD first" -- "$real_just" gate main
no_line '^just check' "gate ran check on an unpushed HEAD"
git push -q origin main 2> /dev/null
box_run 0 "gate: green path" "attest write gate" -- "$real_just" gate main
[ "$(tr '\n' ' ' < "$LOG")" = "just check just sonar attest write gate $(git rev-parse HEAD) " ] || { cat "$LOG"; fail "gate steps or order: $(cat "$LOG")"; }; ok
box_run 1 "gate: failing check stops it" - -- env FAIL_STEP=check "$real_just" gate main
[ "$(tr '\n' ' ' < "$LOG")" = "just check " ] || { cat "$LOG"; fail "gate went past a failed check"; }; ok
box_run 1 "gate: failing sonar stops it" - -- env FAIL_STEP=sonar "$real_just" gate main
[ "$(tr '\n' ' ' < "$LOG")" = "just check just sonar " ] || { cat "$LOG"; fail "gate steps after a failed sonar"; }; ok
box_run 1 "gate: failed attestation propagates" "attest write gate" -- env ATTEST_FAIL=1 "$real_just" gate main
box_run 0 "gate: default base" "attest write gate" -- "$real_just" gate
# The CI-change guard: every path of its pathspec, the only stop before a branch's own justfile
# runs with the owner's keys; GATE_CI_CHANGE must be exactly 1.
for p in scripts/new.sh justfile lefthook.yml mise.toml mise.lock typos.toml .gitleaks.toml .gitleaksignore package.json package-lock.json .github/x.yml sonar-project.properties; do
  fresh; mkdir -p "$(dirname "$p")"; echo '# x' >> "$p"
  git add "$p"; git commit -qm 'ci: touch' --no-verify; git push -qf origin HEAD:cichg 2> /dev/null
  box_run 1 "gate: a branch changing $p refused" "changes the local CI itself ($p" -- "$real_just" gate origin/main
  no_line '^just check' "gate ran check on a branch changing $p"
done
box_run 1 "gate: GATE_CI_CHANGE=true is not the opt-in" "changes the local CI itself" -- env GATE_CI_CHANGE=true "$real_just" gate origin/main
box_run 0 "gate: the same branch gated after reading" "attest write gate" -- env GATE_CI_CHANGE=1 "$real_just" gate origin/main
fresh
box_run 1 "gate: HEAD moved during the run" "HEAD moved" -- env MOVE_HEAD=1 "$real_just" gate main
no_line '^attest' "gate attested a HEAD that moved"
fresh
# The base moves on the remote from another clone: only the gate's own fetch can see it.
git clone -q "$box/origin" "$box/other" 2> /dev/null
git -C "$box/other" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m 'chore: ahead' --no-verify
git -C "$box/other" push -q origin main 2> /dev/null
box_run 1 "gate: HEAD behind a base that moved on the remote" "behind origin/main" -- "$real_just" gate origin/main
no_line '^just check' "gate ran check on a HEAD behind the base"
git pull -q --ff-only origin main 2> /dev/null

# merge: argument shape, the attestation, the exact gh command.
for bad in --help '' '7;id'; do
  box_run 1 "merge: PR argument '$bad' refused" "usage just merge" -- "$real_just" merge "$bad"
  no_line '^gh' "merge called gh on a bad argument"
done
box_run 1 "merge: unattested head refused" "attest verify gate" -- env ATTEST_FAIL=1 "$real_just" merge 7
no_line 'gh pr merge' "merge merged an unattested head"
head=$(git rev-parse origin/pr7)
[ "$head" != "$(git rev-parse origin/main)" ] || fail "fixture: the PR head must differ from origin/main"; ok
box_run 0 "merge: attested head merged" "gh pr merge 7 --squash --match-head-commit $head" -- "$real_just" merge 7
grep -q "^attest verify gate $head\$" "$LOG" || fail "merge did not verify the head SHA"; ok
printf '#!/bin/sh\nexit 1\n' > scripts/attest.sh
box_run 0 "merge: verifier of origin/main, not the checkout's" "gh pr merge 7" -- "$real_just" merge 7
git checkout -q scripts/attest.sh
box_run 1 "merge: gh pr view failure propagates" "gh pr view 7" -- env GH_FAIL=view "$real_just" merge 7
no_line 'gh pr merge' "merge merged after gh pr view failed"
box_run 1 "merge: gh pr merge failure propagates" "gh pr merge 7" -- env GH_FAIL=merge "$real_just" merge 7

# sonar: the guards, then the call with the token in the environment and the gate wait.
mkdir "$box/bare" && for b in sh git cat; do ln -s "$(command -v "$b")" "$box/bare/$b"; done
box_run 1 "sonar: no scanner" "not on PATH" -- env PATH="$box/bare" HOME="$box" "$real_just" sonar
box_run 1 "sonar: no token" "no token" -- env HOME="$box" "$real_just" sonar
no_line sonar-scanner "sonar ran the scanner without a token"
box_run 1 "sonar: server down" "not UP" -- env HOME="$box" SONAR_TOKEN=t0k SONAR_DOWN=1 "$real_just" sonar
no_line sonar-scanner "sonar ran the scanner against a server that is down"
box_run 1 "sonar: server STARTING" "not UP" -- env HOME="$box" SONAR_TOKEN=t0k SONAR_STATUS=STARTING "$real_just" sonar
no_line sonar-scanner "sonar ran the scanner against a server that is starting"
box_run 0 "sonar: scan with the gate wait" "sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.qualitygate.wait=true token=t0k" -- env HOME="$box" SONAR_TOKEN=t0k "$real_just" sonar
grep -q 't0k' "$work/out" && fail "sonar passed the token on the command line"; ok
box_run 0 "sonar: host override" "sonar.host.url=http://sq:9 " -- env HOME="$box" SONAR_TOKEN=t0k SONAR_HOST_URL=http://sq:9 "$real_just" sonar
grep -q 'curl .*http://sq:9/api/system/status' "$LOG" || fail "curl ignored SONAR_HOST_URL"; ok
mkdir -p "$box/.config/sonar-tokens" "$box/.config/sonarqube" && echo gl0b > "$box/.config/sonarqube/analysis-token"
box_run 0 "sonar: global token fallback" "token=gl0b" -- env HOME="$box" "$real_just" sonar
echo f1le > "$box/.config/sonar-tokens/bad-cat"
box_run 0 "sonar: project token beats the global one" "token=f1le" -- env HOME="$box" "$real_just" sonar
box_run 0 "sonar: SONAR_TOKEN beats the files" "token=t0k" -- env HOME="$box" SONAR_TOKEN=t0k "$real_just" sonar
box_run 1 "sonar: failed quality gate fails the recipe" "sonar.qualitygate.wait=true" -- env HOME="$box" SONAR_TOKEN=t0k SCANNER_FAIL=1 "$real_just" sonar
grep -q 't0k' "$work/out" && fail "sonar printed the token on failure"; ok
rm -r "$box/.config"

# toolchain drift: a --bump row of mise.toml other than node, or a Node patch without --bump,
# counts; a Node major bump and a global row do not; the flags are the ones asserted; a failing
# mise fails it.
drift() { box_run "$1" "drift: $2" "$3" -- env MISE_OUT="$4" MISE_PATCH="${5:-}" sh "$root/scripts/toolchain-drift.sh"; }
drift 0 "empty report" "up to date" ''
grep -qx 'mise outdated --bump --no-global --no-header' "$LOG" || fail "drift --bump flags"; ok
grep -qx 'mise outdated --no-global --no-header' "$LOG" || fail "drift patch-pass flags"; ok
drift 0 "global rows ignored" "up to date" 'just  1.0.0  1.1.0  ~/.tool-versions'
drift 0 "a Node major bump is not drift" "up to date" 'node  22  22.23.4  26  26.13.0  mise.toml'
drift 1 "a Node patch is drift" "node  22  22.23.3" 'node  22  22.23.3  26  26.13.0  mise.toml' 'node  22  22.23.3  22.23.4  mise.toml'
drift 1 "a mise.toml row fails" "bump mise.toml" "$(printf 'just  1.0.0  1.1.0  ~/.tool-versions\ntypos  1.0.0  1.1.0  mise.toml')"
cat > "$box/stub/mise" <<'EOF2'
#!/bin/sh
exit 1
EOF2
drift 1 "mise outdated failure propagates" "mise outdated failed" ''
rm "$box/stub/mise"
unset MISE_TRUSTED_CONFIG_PATHS LOG

# L0 in a throwaway repository holding this repository's hook config and scripts.
repo="$work/repo"
mkdir -p "$repo" && cd "$repo"
git init -q -b main && git config user.email t@example.com && git config user.name t
cp -R "$root/scripts" "$root/lefthook.yml" "$root/justfile" "$root/mise.toml" "$root/mise.lock" "$root/typos.toml" .
export MISE_TRUSTED_CONFIG_PATHS="$repo" # not `mise trust`: it would leave a permanent entry for a deleted /tmp path
git add -A && git commit -qm init --no-verify
mkdir notes

fast() { # fast <expected-exit> <label> [<text the output must hold>]
  rc=0; just fast > "$work/out" 2>&1 || rc=$?
  [ "$rc" -eq "$1" ] || { cat "$work/out"; fail "$2: exit $rc, expected $1"; }
  [ -z "${3:-}" ] || grep -qF "$3" "$work/out" || { cat "$work/out"; fail "$2: output lacks '$3'"; }
  ok
}

echo 'Plain notes.' > notes/a.txt && git add notes/a.txt
fast 0 "clean staged change"

key="AKIA$(printf seed | sha256sum | cut -c1-16 | tr 'a-f0-9' 'A-FG-P')"
printf 'token %s\n' "$key" > notes/leak.txt && git add notes/leak.txt
fast 1 "staged secret refused" "leaks found"
git rm -q --cached notes/leak.txt

typo=$(printf 'rec%seve' i) # built at run time: the repository's own typos check must not see it
echo "We $typo a frame." > notes/typo.md && git add notes/typo.md
fast 1 "staged typo refused" "$typo"
git rm -q --cached notes/typo.md

printf '#!/bin/sh\necho $x\n' > notes/bad.sh && git add notes/bad.sh
fast 1 "staged shell warning refused" "SC2154"

# The other two hooks, run by lefthook itself: pre-push refuses the dirty tree left above before
# any check; commit-msg refuses a bad subject.
rc=0; lefthook run pre-push > "$work/out" 2>&1 || rc=$?
[ "$rc" -ne 0 ] && grep -q "commit or set aside" "$work/out" || { cat "$work/out"; fail "pre-push did not refuse a dirty tree"; }; ok
printf 'wip: bad\n' > "$work/m"; rc=0; lefthook run commit-msg "$work/m" > /dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || fail "commit-msg hook accepted a bad subject"; ok

echo "test-local-ci: $n cases passed"
