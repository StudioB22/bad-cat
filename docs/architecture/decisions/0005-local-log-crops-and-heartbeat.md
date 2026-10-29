# ADR-0005: Local structured log, cat crops on the device and heartbeat

bad-cat records its decisions locally, keeps cat crops on the device and emits a heartbeat, with no per-shot push.

- Status: Accepted (owner, 2026-10-28); amended (owner, 2026-10-29): review page deferred to v2
- Issue: #1

## Context

The operator needs to know whether it works and to spot false positives, without images leaving
the local network. aristech ADR-0006/0013 rejected per-detection pushes as noise and added liveness.

## Decision drivers

Weights: simplicity 25, effectiveness 25, autonomy 25, cost 15, reliability/GDPR 10.

## Options (MCDA)

| Option | Simplicity | Effectiveness | Autonomy | Cost | Reliability | Total /500 |
| --- | --- | --- | --- | --- | --- | --- |
| E. Log + cat crops 7 days on LAN + heartbeat | 3 | 5 | 5 | 5 | 5 | **450** |
| D. Log + cat crops | 3 | 5 | 5 | 5 | 4 | 440 |
| C. Local log only | 4 | 3 | 5 | 5 | 4 | 415 |
| B. Telegram + photo | 3 | 5 | 4 | 5 | 3 | 405 |
| A. Nothing | 5 | 1 | 5 | 5 | 3 | 380 |

Sensitivity: simplicity at 40 → C leads (430 vs 410).

## Decision

Option E behind an `EventRecorder` port: JSON-lines log, one line per `Event`, written on every change of decision or
action plus every `FIRE` and `VETO`, cat-only crops, both kept 7 days; heartbeat line every `heartbeat_period` (5 min). The use case
decides what to record; the adapter only writes. The review page is deferred to v2 (owner,
2026-10-29); it will be read-only, bound to the LAN interface and authenticated. In v1 crops are
read over SSH.

## Consequences

- REQ-5, REQ-6, REQ-7, NFR-4; no secrets, no network egress in v1.
