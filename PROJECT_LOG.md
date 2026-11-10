# Project log — bad-cat

Chronological logbook of bad-cat decisions and milestones, newest first; complements `git log`.

## 2026-11-10 — Local CI, no GitHub workflow

- Issue #7 (ADR-0006, owner MCDA 450/500): every check runs locally, `ci.yml` deleted, zero
  workflow left (nothing deploys from GitHub). Tiers L0 `fast` / L1 `check` / L2 `gate` /
  L3 `nightly`, lefthook hooks, mise-pinned tools, mermaid-cli pinned by `package-lock.json`,
  `scripts/attest.sh` + `just merge <pr>` with the `gate` attestation (agents-skills ADR-0003);
  `main` ruleset requires the `gate` status only; Dependabot moved to the `npm` ecosystem.
- Review-local: adversarial Must (Node major reported as drift by `nightly`) fixed by the
  major pin + two-pass drift script; test audit Musts (merge head equal to `origin/main`, base
  fetch unproven) fixed. `just check` under the 3 min budget; wiring tests 112 + 31 cases.
- Bootstrap merge under the owner's waiver (`.github/allowed_signers` not yet on `main`); every
  later merge through `just merge`. Clément: `README.md` § Development.

## 2026-10-30 — Hardware deployment modelled

- Issue #5: owner decisions Raspberry Pi 5 (4 GB) + Camera Module 3 (MCDA 425/500) and one
  protected zone, extensible (445/500); spec open questions closed.
- `08-deployment.md` added; the architecture review tightened the fail-closed chain:
  pull-down-capable pin (BCM 9–27) plus an external pull-down at the relay input,
  opto-isolated relay, non-retriggering power-on timer relay, flyback diode, direct-acting
  valve, RCD on outdoor mains; Picamera2 risk recorded.

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
