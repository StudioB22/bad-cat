# ADR-0002: Use RF-DETR Nano as the cat and person detector

bad-cat detects cats and persons with RF-DETR Nano, the best MIT-compatible detector, with YOLOX-Nano as fallback.

- Status: Accepted (owner, 2026-10-28)
- Issue: #1

## Context

The repository is MIT. Ultralytics YOLOv8/11 is AGPL-3.0 and YOLOv9 GPL-3.0, so they are excluded
(as verified in aristech ADR-0022, 2026-10-19). RF-DETR code and Nano–Large weights are
Apache-2.0 (same source). The COCO classes `cat` and `person` cover v1 without annotation.

## Decision drivers

Weights: licence 30, Pi CPU performance 25, accuracy 20, simplicity 15, maturity 10.

## Options (MCDA)

| Option | Licence | Pi perf | Accuracy | Simplicity | Maturity | Total /500 |
| --- | --- | --- | --- | --- | --- | --- |
| A. RF-DETR Nano | 5 | 3 | 5 | 4 | 4 | **425** |
| B. YOLOX-Nano (weights licence not stated) | 4 | 5 | 3 | 4 | 3 | 395 |
| C. MobileNet-SSD v2 | 4 | 5 | 2 | 3 | 4 | 370 |
| D. Ultralytics YOLO11n | 0 | 5 | 4 | 5 | 5 | 330 |

Sensitivity: Pi performance at 40 (licence 20, accuracy 15) → B 415, A 395: **fragile on Pi
speed**, which is an estimate.

## Decision

RF-DETR Nano from its COCO checkpoint, exported to ONNX, behind a `CatDetector` port. Weights are
git-ignored, loaded from a path, SHA-256 recorded.

## Consequences

- First implementation brick measures frames/s on the target Pi (NFR-1); if below 2 fps, switch
  to YOLOX-Nano after verifying its weights licence.
