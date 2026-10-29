# ADR-0001: Adopt Clean Architecture in Python only

bad-cat is written in Python only and structured as Clean Architecture with proportional layering.

- Status: Accepted (owner, 2026-10-28)
- Issue: #1

## Context

bad-cat runs a camera, a vision model and a valve on a Raspberry Pi. The owner requires Clean
Architecture and SOLID. bad-bird, the sibling project, is almost entirely Python (30.7 kB Python
vs 0.9 kB C++, verified on GitHub 2026-10-28). ONNX Runtime already runs inference in native code.

## Decision drivers

Weights: simplicity 30, effectiveness 30, cost 25, reliability 15. Scores 0–5, estimates.

## Options (MCDA)

| Option | Simplicity | Effectiveness | Cost | Reliability | Total /500 |
| --- | --- | --- | --- | --- | --- |
| A. Python only (OpenCV + ONNX Runtime) | 5 | 4 | 5 | 4 | **455** |
| B. Python + C++ as in bad-bird | 3 | 5 | 4 | 4 | 400 |

Sensitivity: effectiveness at 50 keeps A ahead.

## Decision

Option A, structured as in aristech: `domain` (stdlib only: types, `decide()`, episode state
machine — pure policy with no port) → `application` (use case, ports as `typing.Protocol`) →
`infrastructure` (adapters) → `interface` (CLI, composition root). Unlike aristech, `decide()`
sits in `domain` because it uses no port. Heavy libraries go in an optional `vision` / `hardware` extra.

## Consequences

- Core tested without hardware or model (NFR-2, NFR-6).
- A C++ detector adapter stays possible behind the port if NFR-1 is missed.
