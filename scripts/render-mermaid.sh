#!/bin/sh
# Render every ```mermaid block found in Markdown files under $1; exit non-zero on any parse error.
set -eu
root="${1:-docs}"
[ -d "$root" ] || { echo "no $root directory" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# GitHub runners need Chromium without its sandbox.
printf '{"args":["--no-sandbox"]}\n' > "$work/puppeteer.json"
find "$root" -name '*.md' -print | sort | while IFS= read -r file; do
  # Fences may be indented (list items); the fence's indentation is stripped from its content.
  awk -v out="$work/block" '
    !inside && /^[ \t]*```mermaid/ { n++; inside = 1; indent = index($0, "`") - 1; next }
    inside && /^[ \t]*```[ \t]*$/ { inside = 0; next }
    inside { print substr($0, indent + 1) > (out n ".mmd") }
  ' "$file"
  for block in "$work"/block*.mmd; do
    [ -e "$block" ] || continue
    name="$(basename "$block" .mmd)"
    if npx -y -p @mermaid-js/mermaid-cli@11.4.2 mmdc -p "$work/puppeteer.json" -i "$block" -o "$work/out.svg" >"$work/log" 2>&1; then
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
