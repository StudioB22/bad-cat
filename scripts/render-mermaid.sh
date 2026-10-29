#!/bin/sh
# Render every ```mermaid block found in Markdown files under $1; exit non-zero on any parse error.
set -eu
root="${1:-docs}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# GitHub runners need Chromium without its sandbox.
printf '{"args":["--no-sandbox"]}\n' > "$work/puppeteer.json"
status=0
for file in $(find "$root" -name '*.md' | sort); do
  awk -v out="$work/block" '
    /^```mermaid/ { n++; inside = 1; next }
    /^```/ && inside { inside = 0; next }
    inside { print > (out n ".mmd") }
  ' "$file"
  for block in "$work"/block*.mmd; do
    [ -e "$block" ] || continue
    if npx -y -p @mermaid-js/mermaid-cli@11.4.2 mmdc -p "$work/puppeteer.json" -i "$block" -o "$work/out.svg" >/dev/null 2>&1; then
      echo "OK   $file"
    else
      echo "FAIL $file"
      status=1
    fi
    rm -f "$block"
  done
done
exit "$status"
