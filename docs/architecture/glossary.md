# Glossary

Domain terms used across the bad-cat conception documents, in alphabetical order.

| Term | Definition | Source |
| --- | --- | --- |
| Absence grace | Continuous time without a detected cat (1 s by default) after which the cat counts as gone. | REQ-4 |
| Abstain | Decision not to fire because the cat confidence is below the cat threshold. | ADR-0004 |
| Action | Output of the episode state machine for a frame: `FIRE`, `VETO`, `WAIT`, `ABSTAIN` or `IGNORE`. | `05-state-episode.md` |
| Burst | One opening of the valve, 0.5 s by default, always below the 3 s relay cap. | REQ-4, REQ-9 |
| Cat threshold | Minimum cat confidence required to fire. | REQ-2 |
| Cooldown | Period during which the device never fires: 60 s by default, never below 10 s, after an episode, after any veto, or at every (re)start. | REQ-3, REQ-4 |
| Crop | Image of the detected cat's bounding box only, saved on `FIRE`, kept 7 days. | REQ-6 |
| Daylight threshold | Minimum frame brightness for `is_daylight()`; below it the decision is `IGNORE` (dark). | REQ-1 |
| Decision | Output of `decide()` for a frame: `FIRE`, `VETO`, `ABSTAIN` or `IGNORE`. | ADR-0004 |
| Event | Domain value written to the log: action, decision, confidences, `captured_at`. | REQ-5 |
| Episode | One cat visit: up to 3 bursts, ended by the cat leaving, a veto or the burst limit. | REQ-4 |
| Fault | Camera, model, valve or recorder error; written to stderr, ends the loop with the valve closed, exit non-zero. | UC1 ext. *a |
| Gardener | Role of the person who arms, pauses, tunes and monitors the device. | `01-use-case.md` |
| Heartbeat | Periodic log line proving the device is alive. | REQ-7 |
| Hold-off | The cooldown started by a veto or by a (re)start; never below 10 s. | REQ-3, REQ-9 |
| Ignore | Decision when no cat is in the frame, or when the frame is too dark (daylight rule). | REQ-1, REQ-5 |
| One-shot timer relay | Hardware relay between the valve relay and the coil; cuts the 12 V coil after 3 s whatever the GPIO does (the relay cap of REQ-9). | ADR-0003, `08-deployment.md` |
| Person threshold | Minimum person confidence that triggers a veto; always below the cat threshold. | REQ-3, REQ-9 |
| Port | Interface (`typing.Protocol`) in `application/` that an infrastructure adapter realises. | ADR-0001 |
| Recheck delay | Wait after a burst before the device may fire again in the same episode, 5 s by default. | REQ-4 |
| Veto | Decision not to fire because a person is detected; starts the full cooldown. | REQ-3 |
| Wait | Action when a cat is decided `FIRE` but a burst is not due (recheck delay or cooldown). | `05-state-episode.md` |
