# ADR-0004: Veto firing on any person, abstain by default

bad-cat never fires while a person is detected, holds off after any veto, and abstains when unsure.

- Status: Accepted (owner, 2026-10-28)
- Issue: #1

## Context

Spraying a person (a neighbour, a child, the gardener) is a safety and liability issue, not a
quality defect. The COCO detector reports `person` alongside `cat`. Pattern taken from aristech
ADR-0003.

## Decision drivers

Weights: simplicity 25, effectiveness 25, autonomy 25, cost 15, safety 10.

Safety is a pass/fail constraint, checked before scoring: an option that may spray a person is
excluded whatever its total.

## Options (MCDA)

| Option | Simplicity | Effectiveness | Autonomy | Cost | Safety | Total /500 |
| --- | --- | --- | --- | --- | --- | --- |
| A. `person` veto | 5 | 4 | 5 | 5 | 5 | **475** |
| C. Veto + physical pause switch | 4 | 4 | 5 | 4 | 5 | 435 |
| B. No rule | 5 | 4 | 5 | 5 | 0 | 425, excluded on safety |

## Decision

- `decide()` returns `VETO` when any `person` is detected at or above `person_threshold`; else
  `FIRE` for a cat at or above `cat_threshold`; `ABSTAIN` for a cat below it; `IGNORE` otherwise
  (including dark frames).
- `person_threshold` < `cat_threshold` (default 0.3 and 0.6, to tune), validated at start (REQ-9),
  so doubt about a person always blocks.
- `CatDetector.detect(frame, min_confidence)` receives `person_threshold` from the use case on
  every call and returns every box at or above it; the adapter has no floor of its own.
- A `VETO` in any episode state starts or restarts the full cooldown, never below 10 s (REQ-9),
  so a person missed for one frame never triggers a jet (`05-state-episode.md`).

## Veto during a burst (owner, 2026-10-29)

No frame is read while the valve is open, so a person entering during a burst is not vetoed
until it ends (Codex review on PR #2). Detection takes up to about 0.5 s at NFR-1, so a
cancellable valve would barely close sooner than a short burst ends.

Weights: safety 40, simplicity 25, effectiveness 20, cost 15.

| Option | Safety | Simplicity | Effectiveness | Cost | Total /500 |
| --- | --- | --- | --- | --- | --- |
| E. Blocking burst shortened to 0.5 s, residual risk documented | 3 | 5 | 4 | 5 | **400** |
| B. Non-blocking valve, detection continues, `VETO` closes it | 4 | 2 | 5 | 5 | 385 |
| C. Blocking 1 s burst, residual risk documented | 2 | 5 | 5 | 5 | 380 |
| A. Burst split into 0.25 s slices with a re-check between them | 3 | 3 | 3 | 5 | 330 |

Sensitivity: effectiveness at 35 → B 395 vs E 390 (close); safety at 50 → E 410 vs B 400.
Decision: E. Worst-case exposure is one burst (0.5 s). The first code brick checks that a 0.5 s
jet still deters a cat; if it does not, B is reconsidered.

## Consequences

- REQ-3, REQ-9; the veto is a pure domain rule, unit-tested exhaustively.
- The owner's own cat cannot be told apart in v1 (accepted risk).
