#!/bin/sh
# Toolchain drift (step of `just nightly`): fails when a tool pinned in mise.toml is behind. `mise
# outdated` exits 0 whatever it finds and still lists the global ~/.tool-versions under --no-global,
# so only the mise.toml rows count. Every pin is exact, so one `--bump` pass sees them all.
set -eu
bump=$(mise outdated --bump --no-global --no-header) || { echo "toolchain-drift: mise outdated --bump failed" >&2; exit 1; }
drift=$(printf '%s\n' "$bump" | grep -F mise.toml || true)
[ -z "$drift" ] || { echo "toolchain-drift: bump mise.toml:"; echo "$drift"; exit 1; }
echo "toolchain-drift: mise.toml up to date"
