# Project log — bad-cat

Chronological logbook of bad-cat decisions and milestones, newest first; complements `git log`.

## 2026-10-29 — Baseline CI

- PR #4 merged (058d629, closes #3): GitHub Actions run gitleaks on full history and render every
  Mermaid block; Dependabot for actions. SonarQube scanned locally (`localhost:9000`, project
  `bad-cat`, gate passed); GitHub CI cannot reach the local server.
- Codex review: indented Mermaid fences were skipped; fixed before merge.

## 2026-10-29 — UML dossier hardened

- Two more review passes applied. Owner decisions: LAN review page deferred to v2 (crops read
  over SSH in v1); cooldown never below 10 s (veto hold-off floor).
- Episode now starts in `Cooldown`, so a restart never clears a veto hold-off; settings
  validated in the domain; record policy moved into the use case; faults go to stderr.

## 2026-10-28 — Project creation and framing

- Repository `StudioB22/bad-cat` created (public, MIT); Clément (`yazii`) invited as admin; wiki
  and Discussions enabled.
- Issue #1 opened: model the detection system in UML, preceded by a brainstorm and a framing
  debrief.
- Brainstorm doc shared with Clément; eleven v1 decisions taken (ten framing decisions plus the
  absence grace), recorded as ADR-0001 to ADR-0005 and in
  `docs/architecture/specs/cat-detection-requirements.md`.
- UML dossier `diagrams/cat-detection/` (use case, sequence, component, episode state machine),
  each diagram critically reviewed; the review added the veto hold-off, the person threshold and
  the fail-closed GPIO and timer-relay guards.
- Model choice corrected from Ultralytics YOLO (AGPL-3.0, incompatible with MIT) to RF-DETR Nano
  (Apache-2.0), following aristech ADR-0022.
