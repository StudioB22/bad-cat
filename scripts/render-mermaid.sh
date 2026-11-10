#!/bin/sh
# Render every ```mermaid block found in Markdown files under $1; exit non-zero on any parse error.
set -eu
root="${1:-docs}"
# mermaid-cli from the lockfile-pinned tree (package-lock.json, `npm ci` in `just setup`), never npx.
mmdc="$(cd "$(dirname "$0")/.." && pwd)/node_modules/.bin/mmdc"
[ -x "$mmdc" ] || { echo "mermaid-cli not installed: run just setup" >&2; exit 1; }
[ -d "$root" ] || { echo "no $root directory" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# Chromium runs without its sandbox: needed on CI runners and inside containers, harmless elsewhere.
printf '{"args":["--no-sandbox"]}\n' > "$work/puppeteer.json"
find "$root" -path '*/node_modules' -prune -o -name '*.md' -print | sort | while IFS= read -r file; do
  # Fences may be indented (list items); the fence's indentation is stripped from its content.
  awk -v out="$work/block" '
    !inside && /^[ \t]*```mermaid/ { n++; inside = 1; indent = index($0, "`") - 1; next }
    inside && /^[ \t]*```[ \t]*$/ { inside = 0; next }
    inside { print substr($0, indent + 1) > (out n ".mmd") }
  ' "$file"
  for block in "$work"/block*.mmd; do
    [ -e "$block" ] || continue
    name="$(basename "$block" .mmd)"
    if "$mmdc" -p "$work/puppeteer.json" -i "$block" -o "$work/out.svg" >"$work/log" 2>&1; then
      echo "OK   $file ($name)"
    else
      echo "FAIL $file ($name)"
      cat "$work/log"
      touch "$work/failed"
    fi
    rm -f "$block"
  done
done
# The loop runs in a subshell, so failures are reported through a marker file.
[ ! -e "$work/failed" ]
