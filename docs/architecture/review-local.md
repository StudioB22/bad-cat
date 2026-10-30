# Local review — bad-cat (issue #5 hardware deployment)

Local review gate (`--push` mode) on the deployment diagram brick, after one design pass and one
docs pass with their fixes applied.

- Date: 2026-10-30
- Commit: a8df22b + review fixes (branch `docs/5-model-hardware-deployment`)
- Scope: branch diff `main...HEAD` — `docs/architecture/`, `PROJECT_LOG.md` (docs only)
- Checks run: design (architecture-guardian, Opus) · docs (doc-auditor) · secrets; tests,
  security and correctness not applicable (no code)
- Verdict: ship as-is · Must 0 · Should 0 · Nice 2

## Pre-merge gate (head SHA of this commit)

| Step | Result |
| --- | --- |
| 1 Tests | Not applicable (no code yet); Mermaid render check: all blocks OK |
| 2 Coverage | Not applicable (no code yet) |
| 3 SonarQube | ✅ PASSED (local, project `bad-cat`) |
| 4 Secrets | ✅ gitleaks clean (`main..HEAD` and working tree) · no tracked `.env` · diff read: no address, host name or credential |
| 5 QA pass | Not run (`--push` mode; docs-only diff, no running product) |

- Gate: **GREEN for push**; merge after CI and the owner's approval.

## 🔴 Must Have

- Design M1–M4 (UML `«deploy»`/`«manifest»` misuse, pull-down overclaim, timer relay mode) and
  docs Must (stale fail-closed bullet in `03-component.md`): fixed.

## 🟡 Should Have

- Design S1–S6 (isolation boundary, flyback diode, Picamera2 risk, over-detailed edges, RCD,
  direct-acting valve) and docs Should 2–4, 6: fixed. Docs 5 (timer → coil edge): already drawn
  as `12 V coil, ≤ 3 s`.

## 🔵 Nice to Have

- `diagrams/cat-detection/08-deployment.md` `[design]` · name the wheel like its build output with
  a version once packaging exists.
- `diagrams/cat-detection/08-deployment.md` `[docs]` · 10 kΩ value indicative only; size it in the
  hardware brick.

## ⚪ Disagree / Intentional

- Two separate supplies, the multi-zone note and the laptop on the prod canvas: intentional
  (owner decisions, declared ingress client).

## Per-dimension summary

- Design: orthodoxy and NFR-5 wiring fixed · Docs: cross-document consistency restored ·
  Tests: n/a · Security: SSH-only ingress, no secrets · Correctness: n/a
