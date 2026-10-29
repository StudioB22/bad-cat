# Cat detection — requirements

What bad-cat v1 must do, independent of how it is built; decided on 2026-10-28 (issue #1).

## Root need

Keep cats away from the plants without harming them, without spraying people, and without daily
human labour.

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| REQ-1 | Detect a cat in the camera view in daylight; on dark frames, never fire. | Brainstorm |
| REQ-2 | Fire the water jet only when a cat is detected at or above the cat threshold. | Brainstorm |
| REQ-3 | Never fire while a person is detected at or above the person threshold anywhere in the frame (`person` veto); a veto holds off firing for the full cooldown; abstain when the cat confidence is below the cat threshold. | [ADR-0004](../decisions/0004-veto-on-person-abstain-by-default.md) |
| REQ-4 | Adaptive jet: 0.5 s burst; if the cat is still present 5 s later, fire again, at most 3 bursts per episode; then a 60 s cooldown. The cat counts as gone only after 1 s of continuous absence (absence grace). All five values configurable. | Brainstorm, MCDA 440/500 (jet), 475/500 (absence grace) |
| REQ-5 | Record in a structured local log every change of decision or action, plus every `FIRE` and `VETO`, with timestamp and confidences; keep the log 7 days. | [ADR-0005](../decisions/0005-local-log-crops-and-heartbeat.md) |
| REQ-6 | Keep a crop of the detected cat for each fired episode, 7 days, on the device only (read over SSH in v1). | ADR-0005 |
| REQ-7 | Emit a periodic heartbeat proving the device is alive. | ADR-0005 |
| REQ-8 | Let the operator pause firing without powering off (stopping the service in v1). | Brainstorm |
| REQ-9 | Refuse to start on invalid settings: 0 < person threshold < cat threshold ≤ 1; 0 < burst < hardware relay cap (3 s); `max_bursts` ≥ 2; absence grace > 0; recheck delay > 0; cooldown ≥ 10 s (veto hold-off floor, owner 2026-10-29); heartbeat period > 0. | Design review |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Detection throughput of at least 2 frames/s on the target Pi (to be measured; fallback model if not met). |
| NFR-2 | `domain/` imports the standard library only; `application/` imports `domain/` and the standard library; adapters hold OpenCV, ONNX Runtime and GPIO. |
| NFR-3 | Every dependency and model weight is licence-compatible with MIT (no AGPL/GPL). |
| NFR-4 | No image leaves the local network; no frame containing a person is stored. |
| NFR-5 | The jet never opens or stays open by accident: NC valve (power loss); coil de-energised in every undriven GPIO state (boot, exit) through a pull-down pin and an active-high relay; software close in `try/finally` with a SIGTERM handler; hardware one-shot timer relay capping the coil at 3 s (hang, kill). Tested at boot. |
| NFR-6 | Unit test coverage ≥ 80 % on domain and application; core tests run without hardware. |

## Settings

All in `config.yaml`, validated at start (REQ-9): `cat_threshold` (0.6), `person_threshold`
(0.3), `daylight_threshold` (to tune), `burst` (0.5 s), `recheck_delay` (5 s), `max_bursts` (3),
`absence_grace` (1 s), `cooldown` (60 s), `heartbeat_period` (5 min). The relay cap (3 s) is a
hardware constant, not a setting.

## Constraints

- Hardware: Raspberry Pi (model to confirm), standard camera, 12 V NC solenoid valve via an
  active-high relay and a one-shot timer relay, 5–8 L hand-pressurised garden sprayer, mains power.
- Software: Python ≥ 3.10, OpenCV, ONNX Runtime, RF-DETR Nano exported to ONNX.
- Repository public, MIT licence.

## Decisions taken (summary)

| Topic | Decision | Score /500 | Record |
| --- | --- | --- | --- |
| Architecture & stack | Clean Architecture, Python only | 455 | ADR-0001 |
| Model | RF-DETR Nano (Apache-2.0), YOLOX-Nano fallback | 425 | ADR-0002 |
| Water | Pressurised sprayer + solenoid valve + timer relay | 390 | ADR-0003 |
| Safety | `person` veto with hold-off, abstain by default | 475 | ADR-0004 |
| Monitoring | Log + cat crops on the device + heartbeat; LAN review page in v2 | 450 | ADR-0005 |
| Jet | Adaptive 0.5 s ×3, then 60 s cooldown | 440 | this spec (REQ-4) |
| Veto during a burst | Blocking 0.5 s burst, residual exposure documented | 400 vs 385 (cancellable valve) | ADR-0004 |
| Absence grace | 1 s of continuous absence before the cat counts as gone | 475 | this spec (REQ-4) |
| Aiming | Single fixed nozzle, extensible to multi-zone | 440 | this spec |
| Hours | Daylight only | 440 | this spec |
| Power | Mains in v1 | — | this spec |
| Roles | Benoît and Clément on everything, split per issue | — | this spec |
| Veto hold-off floor | Cooldown never below 10 s | — | this spec (REQ-9) |
| LAN review page | Deferred to v2; crops read over SSH in v1 | 440 (vs 290; MCDA 2026-10-28, owner decision 2026-10-29) | this spec (REQ-6) |

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| RF-DETR too slow on the Pi CPU | NFR-1 missed | Measure early; swap to YOLOX-Nano behind the `CatDetector` port |
| Nano model misses a person for one frame | Person sprayed | Lower person threshold and veto hold-off of at least 10 s (REQ-3, REQ-9) |
| Person enters the jet zone during a burst | Sprayed for at most one burst (0.5 s) | Short burst; no frame is read while the valve is open, and a cancellable valve would not close faster than detection (~0.5 s at NFR-1) (ADR-0004) |
| Relay board energises at boot | Jet opens unattended | Pull-down pin, active-high relay, boot test (NFR-5) |
| COCO cannot tell the owner's own cat from others | Own cat sprayed | Accepted in v1; fine-tuning later |
| Sprayer pressure drops as it empties | Weaker jet | Refill/pump reminder from the shot count in the log |
| Camera films beyond the garden | GDPR exposure | Aim the camera at the plants only; store cat crops only (NFR-4); `VETO` lines carry no image and expire after 7 days |
| False positive on a moving object | Wasted water | Threshold tuned on logged crops (REQ-6) |

## Open questions

- Raspberry Pi model and camera on hand?
- Number of protected zones (drives the multi-zone extension)?
