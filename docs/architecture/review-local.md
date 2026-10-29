# Local review — bad-cat (issue #1 conception dossier)

Third pass of the local review gate on the UML dossier, after two rounds of fixes.

- Date: 2026-10-29
- Commit: 3a571a2 (dossier uncommitted on `docs/1-model-cat-detection-uml`)
- Scope: `docs/architecture/`, `PROJECT_LOG.md` (docs only)
- Checks run: design (architecture-guardian, three passes) · docs · secrets
- Verdict: ship as-is · Must 0 · Should 0 · Nice 0

## Pre-merge gate (head SHA 3a571a2 + working tree)

| Step | Result |
| --- | --- |
| 1 Tests | ⚠️ not applicable: no code yet (docs-only diff); owner waiver requested |
| 2 Coverage | ⚠️ not applicable: no code yet; owner waiver requested |
| 3 SonarQube | ⚠️ not run: no SonarQube project yet; owner waiver requested |
| 4 Secrets | ✅ gitleaks clean (working tree) · no tracked .env · diff read: nothing sensitive |
| 5 QA pass | ✅ smoke (docs diff): the four diagrams and the README context diagram render with mmdc 11.4.2 |

- Gate: **RED until the owner waives steps 1–3** for this docs-only PR.

## History

- Pass 1 (2026-10-28): Must 7, Should 13, Nice 6, all applied.
- Pass 2 (2026-10-29): Must 1 (cooldown not validated), Should 7 (record policy in use case,
  single `Event`, faults to stderr, validation in `Settings.__post_init__`,
  `detect(frame, min_confidence)`, opaque `Frame.image`, UC1 guarantee and REQ-6 scope), Nice 9;
  all applied with owner decisions: LAN review page deferred to v2, cooldown floor 10 s.
- Pass 3 (2026-10-29): Should 2 (a restart cleared the veto hold-off → the episode now starts in
  `Cooldown`; the cat was still drawn as an actor), Nice 3 (ADR-0005 wording, score source, fault
  visibility); all applied.
- Pass 4 (2026-10-29): Nice 2 (startup cooldown in glossary and UC1, score date), applied; no
  Must or Should.

## 🔴 Must Have

_None._

## 🟡 Should Have

_None._

## 🔵 Nice to Have

_None._

## ⚪ Disagree / Intentional

- `traceability-matrix.md` `[docs]` · keep the `REQ-n →` prefix in link cells · required by
  `conception-naming` (explicit pairs).
- `05-state-episode.md` `[design]` · self-loops drawn for internal transitions · Mermaid cannot
  draw them; stated in the notes.
- `03-component.md` `[design]` · no clock port, one `EventRecorder` port · simpler, still
  deterministic to test.

## Per-dimension summary

- Design: dependency rule respected, state machine deterministic and exhaustive, no
  over-engineering · Docs: IDs, parameters and file names consistent · Tests: n/a (no code) ·
  Security: veto, hold-off floor and four fail-closed layers specified; no secrets · Correctness:
  MCDA totals recomputed.
