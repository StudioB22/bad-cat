# Traceability matrix

Links each requirement and use case to the diagrams that realise it; link cells hold explicit
pairs.

## Requirements

| Requirement | Use case | Component | Sequence / state | Status |
| --- | --- | --- | --- | --- |
| REQ-1 | REQ-1 → UC1 step 3, ext. 2a | REQ-1 → `is_daylight()`, `CatDetector` | REQ-1 → SEQ-deter-cat (daylight alt) | planned |
| REQ-2 | REQ-2 → UC1 step 3; UC5 | REQ-2 → `decide()`, `Settings` | REQ-2 → SEQ-deter-cat (decide) | planned |
| REQ-3 | REQ-3 → UC1 ext. 3a, 5b | REQ-3 → `decide()` veto, `detect(frame, min_confidence)`, cooldown floor | REQ-3 → SEQ-deter-cat; `05-state-episode.md` (VETO → Cooldown in every state) | planned |
| REQ-4 | REQ-4 → UC1 step 4–5, ext. 5a; UC5 | REQ-4 → Episode state machine, `WaterValve.pulse` | REQ-4 → `05-state-episode.md` | planned |
| REQ-5 | REQ-5 → UC1 step 4, ext. 3a–3c; UC3 | REQ-5 → use-case record policy, `Event`, `EventRecorder.record`, purge | REQ-5 → SEQ-deter-cat (record) | planned |
| REQ-6 | REQ-6 → UC1 step 4; UC3 | REQ-6 → `EventRecorder.save_crop`, purge | REQ-6 → SEQ-deter-cat (save_crop on FIRE) | planned |
| REQ-7 | REQ-7 → UC4 | REQ-7 → `EventRecorder.heartbeat`, `Frame.timestamp` | REQ-7 → SEQ-deter-cat (heartbeat opt) | planned |
| REQ-8 | REQ-8 → UC2; UC1 ext. *b | REQ-8 → service stop, SIGTERM handler | REQ-8 → SEQ-deter-cat (loop until SIGTERM) | planned |
| REQ-9 | REQ-9 → UC1 preconditions; UC5 | REQ-9 → `Settings.__post_init__` (domain) | REQ-9 → SEQ-deter-cat (settings validated) | planned |
| NFR-1 | — | NFR-1 → `OnnxRfDetrDetector`; measured on the Raspberry Pi 5 (`08-deployment.md`) | — | to measure |
| NFR-2 | — | NFR-2 → layer boundaries | — | planned |
| NFR-3 | — | NFR-3 → ADR-0002 (RF-DETR Apache-2.0) | — | planned |
| NFR-4 | NFR-4 → UC1 ext. 3a | NFR-4 → `save_crop` only on `FIRE`, crops on the device; SSH-only LAN ingress (`08-deployment.md`) | NFR-4 → SEQ-deter-cat | planned |
| NFR-5 | NFR-5 → UC1 minimal guarantee, ext. *a | NFR-5 → NC valve, pull-down pin + external pull-down (opto-isolated relay), `pulse` try/finally, non-retriggering timer relay; layer-to-node table in `08-deployment.md` | NFR-5 → SEQ-deter-cat (break) | planned |
| NFR-6 | — | NFR-6 → domain and application tests | — | planned |

## Use cases

| Use case | Requirements | Diagrams |
| --- | --- | --- |
| UC1 Protect plants unattended | REQ-1–REQ-7, REQ-9, NFR-4, NFR-5 | UC1 → SEQ-deter-cat; `05-state-episode.md` |
| UC2 Pause deterrence | REQ-8 | UC2 → SEQ-deter-cat (loop exit) |
| UC3 Review deterrence episodes | REQ-5, REQ-6 | UC3 → SSH in v1 (`08-deployment.md`); LAN page v2 adapter |
| UC4 Check device health | REQ-7 | UC4 → SSH in v1 (log, journald; `08-deployment.md`) |
| UC5 Tune deterrence settings | REQ-2, REQ-4, REQ-9 | UC5 → `Settings` |
