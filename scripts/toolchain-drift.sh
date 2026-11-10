#!/bin/sh
# Toolchain drift (step of `just nightly`): fails when a tool pinned in mise.toml is behind. `mise
# outdated` exits 0 whatever it finds and still lists the global ~/.tool-versions under --no-global,
# so only the mise.toml rows count. Two passes: without `--bump`, a new patch of the Node major pin
# (`node = "22"`: the next major is the project's choice, not drift); with `--bump`, a new release
# of every exact pin (without it exact pins report nothing).
set -eu
patch=$(mise outdated --no-global --no-header) || { echo "toolchain-drift: mise outdated failed" >&2; exit 1; }
bump=$(mise outdated --bump --no-global --no-header) || { echo "toolchain-drift: mise outdated --bump failed" >&2; exit 1; }
drift=$({ printf '%s\n' "$patch" | grep -E '^node '; printf '%s\n' "$bump" | grep -vE '^node '; } | grep -F mise.toml || true)
[ -z "$drift" ] || { echo "toolchain-drift: bump mise.toml:"; echo "$drift"; exit 1; }
echo "toolchain-drift: mise.toml up to date"
