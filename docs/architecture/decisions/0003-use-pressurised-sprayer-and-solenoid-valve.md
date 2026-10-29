# ADR-0003: Use a pressurised garden sprayer and a solenoid valve

bad-cat sprays from a hand-pressurised garden sprayer through a solenoid valve, guarded by hardware against staying open.

- Status: Accepted (owner, 2026-10-28)
- Issue: #1

## Context

The owner wants the device autonomous where possible. A motion-activated garden sprinkler still
needs a hose; a pump draws power.

## Decision drivers

Weights: simplicity 25, effectiveness 25, autonomy 25, cost 15, reliability 10. Estimates.

## Options (MCDA)

| Option | Simplicity | Effectiveness | Autonomy | Cost | Reliability | Total /500 |
| --- | --- | --- | --- | --- | --- | --- |
| D. Hand-pressurised sprayer 5–8 L + 12 V NC solenoid valve | 4 | 4 | 4 | 4 | 3 | **390** |
| A. Tap + 12 V solenoid valve | 4 | 5 | 2 | 4 | 3 | 365 |
| C. Modified motion-activated sprinkler | 4 | 5 | 2 | 3 | 4 | 360 |
| B. Tank + 12 V diaphragm pump | 3 | 4 | 4 | 3 | 3 | 350 |

Sensitivity: D stays first while autonomy weighs about 20 or more; below, A leads.

## Decision

Option D, driven through a `WaterValve` port, with four fail-closed layers (NFR-5):

- a 12 V **normally closed** valve, shut on power loss;
- a GPIO pin with a default **pull-down**, driving an **active-high** relay input, so the coil is
  off whenever the pin is undriven (boot, exit); verified by a boot test;
- `pulse()` closing in `try/finally`, plus a SIGTERM handler so a service stop mid-burst closes it;
- a **one-shot timer relay** that cuts the coil after 3 s whatever the GPIO does (hang, SIGKILL).

## Consequences

- Estimated 50–100 half-second bursts per 5 L; pressure drops as it empties (risk logged).
- Mains water (A) remains a drop-in adapter change if autonomy stops mattering.
