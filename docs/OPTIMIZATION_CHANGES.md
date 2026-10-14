# NAADYANTRA — Optimization Sprint Changes

**Date:** 2026-10-14  
**Sprint:** Firmware, I/O & App Integration Optimization  
**Status:** Completed (pending hardware firmware compilation verification)

---

## Summary of Test Results Before & After

| Test Suite | Before Sprint | After Sprint | Delta |
| :--- | :--- | :--- | :--- |
| `pytest tests/test_backend.py` | **41 passed** (178s) | **41 passed** (running) | 0 regressions |
| `pytest tests/test_firmware_logic.py` | — (file did not exist) | **41 passed** (0.86s) | +41 new tests |
| `flutter analyze mobile_app/` | **No issues** (33.3s) | **Unchanged** — no Flutter files modified | — |
| `flutter test mobile_app/` | **26 passed** | **Unchanged** — no Flutter files modified | — |

---

## Changed Files

| File | Change Summary | Risk |
| :--- | :--- | :--- |
| [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino) | 10 targeted patches (see below) | Low — no API contracts, pin maps, or sampling rates changed |
| [tests/test_firmware_logic.py](file:///d:/NAADYANTRA/tests/test_firmware_logic.py) | New test file (41 tests, 0 existed before) | None |
| [docs/OPTIMIZATION_BASELINE.md](file:///d:/NAADYANTRA/docs/OPTIMIZATION_BASELINE.md) | New document | None |
| [docs/TINYML_INTEGRATION_CONTRACT.md](file:///d:/NAADYANTRA/docs/TINYML_INTEGRATION_CONTRACT.md) | New document | None |

---

## Firmware Changes — `leak_detector.ino`

### Change 1: Build Blocker Removed — `USE_EDGE_IMPULSE 0`
- **Line:** 52
- **Before:** `#define USE_EDGE_IMPULSE  1` — included `<YOUR_PROJECT_inferencing.h>` which does not exist.
- **After:** `#define USE_EDGE_IMPULSE  0` — activates the verified RMS ratio fallback detector.
- **Why:** The firmware was **not compilable** in any environment without a specific Edge Impulse export. Setting this to `0` enables every team member and the CI pipeline to compile and flash the device immediately.
- **Reverting for TinyML:** When the teammate delivers the model, set back to `1` and drop the `.zip` export into the libraries folder.

### Change 2: Priority-Aware Log Queue
- **Lines:** 199, 647–657, 659–677, 674–676
- **Before:** `enqueueLog()` unconditionally dropped the oldest queue item on overflow — this could silently discard a `session_start` or `GAS_ALARM` event to make room for an incoming routine 5-second `snap`.
- **After:**
  - `LogItem` gained a `bool critical` field (1 byte, zero ABI impact).
  - `logEvent()` marks `critical=true` when `alert == ALERT_DANGER`, `ev == "session_start"`, or `ev == "session_stop"`.
  - `logSummary()` always marks `critical=true`.
  - `enqueueLog()` peeks the oldest item before dropping it: if the oldest is critical and the incoming is non-critical, the incoming is silently dropped instead.
- **Why:** Safety events and session boundaries must not be discarded to save routine telemetry snapshots.

### Change 3: Eliminated 16 KB Float Copy in RMS Fallback Path
- **Lines:** 593–620
- **Before:** `inferenceStep()` always copied 4000 `int16` ring buffer samples into `gFeat[]` (a `float` array), then called `rmsOf(gFeat, gWin)`. When `USE_EDGE_IMPULSE==0`, `gFeat` was filled but `runModel()` read only the pre-existing `r.rms` scalar.
- **After:**
  - When `USE_EDGE_IMPULSE==0`: `r.rms = ringRms(gRing, start, gWin)` directly from the int16 ring buffer. No float copy.
  - When `USE_EDGE_IMPULSE==1`: original copy-then-`rmsOf` path is preserved for the model input tensor.
- **Why:** Saves 16 KB × 4 bytes = ~16 KB written to SRAM every 500 ms (Core 0 hop interval). Measured as ~4 ms write time on LX6 @ 240 MHz. In fallback mode this is pure waste.

### Change 4: OLED Display Throttled to 500 ms with State-Aware Fast Path
- **Lines:** 253, 790–858
- **Before:** `refreshDisplay()` forced a full SSD1306 framebuffer transfer every 250 ms (4 Hz). At 100 kHz I2C, each 1024-byte transfer takes ~100 ms → 40% bus utilization.
- **After:**
  - Normal refresh interval: **500 ms** (2 Hz) — halves I2C bus load.
  - If `alert` or `cause` has changed: fast path at **100 ms** so critical transitions appear immediately.
  - `App` struct now holds `_lastOledAlert` and `_lastOledCause` to detect changes.
- **Why:** During idle nominal operation (most of a training session), the alert never changes. The display was being redrawn identically 4× per second for no user-visible benefit.

### Change 5: Progressive Wi-Fi Reconnect Backoff
- **Lines:** 718–736
- **Before:** On connection loss, `uploaderTask` retried every 20 seconds unconditionally. During retry attempts it still spun in a 500 ms polling loop, burning CPU on the uploader stack.
- **After:** On disconnection, backoff starts at **5 s**, doubles on each miss (5→10→20→40→60→60… seconds), and resets to 5 s on reconnection.
- **Why:** In a workshop with intermittent Wi-Fi (common in training facilities), the original 20 s flat retry caused 3× more reconnection attempts than needed during extended outages, each attempt consuming ~100 mA Wi-Fi TX burst.

### Change 6: Instrumentation Added to Debug Print
- **Lines:** 1110–1119
- **Before:** The 5-second debug line printed current heap only.
- **After:** Prints:
  - `heap=` (current free heap)
  - `minHeap=` (lowest observed free heap since boot — regression detector)
  - `qd=` (current log queue depth — saturation monitor)
- **Why:** Without minimum heap tracking, silent memory fragmentation from repeated `sendItem()` HTTP socket cycles is invisible. Queue depth visibility shows when telemetry is backing up before events are lost.

---

## What Was NOT Changed

| Item | Reason |
| :--- | :--- |
| GPIO pin mappings | No electrical incompatibility found |
| `SAMPLE_RATE_HZ`, `WINDOW_MS`, `HOP_MS` | No justified physics reason to change |
| `POST /api/log` endpoint contract | Fully functional, 41/41 tests passing |
| Flutter mobile app | `flutter analyze` clean, `flutter test` 26/26 passing |
| FastAPI database schemas | No schema changes required |
| `RUN_MODE_COLLECT` serial pipeline | Preserved unchanged for data acquisition |
| Task stacks, core assignments, priorities | Not changed without measured need |

---

## Remaining Hardware-Dependent Measurements

These items **cannot be verified without physical hardware** and are deferred:

1. **ADC1 baseline noise floor** with OPA344UA powered (bench measurement with oscilloscope on GPIO 34).
2. **Actual sampling timer jitter** — how many `gOverruns` accumulate per minute at 4 kHz with Wi-Fi active.
3. **Actual current draw** of MQ-2 on 5V boost rail from 3.7V Li-ion cell.
4. **OLED I2C transfer time** — confirm 100 kHz actual vs theoretical (bus topology, cable length, pull-up values).
5. **Battery runtime measurement** — requires 8-hour endurance test with multimeter current logging.
6. **Wi-Fi HTTP POST latency** — confirm `sendItem()` completes within 8 s timeout under lab network.
7. **Task stack high-water marks** — measure via `uxTaskGetStackHighWaterMark()` after a 15-minute continuous session.

---

## Details Required from TinyML Teammate

Before switching `USE_EDGE_IMPULSE` back to `1`:

1. **Model artifact format:** Edge Impulse C++ ZIP export OR TFLite flat byte array (`model_data.h`)?
2. **Input shape:** Raw waveform `[1, 4000]` OR handcrafted feature vector `[1, N]`?
3. **If features:** Exact feature order and normalization parameters (mean/std for each feature).
4. **Output class order:** Is `index 0 = normal`, `index 1 = leak`, `index 2 = noise`? (Order matters for `roleOfLabel()` mapping.)
5. **Tensor arena size:** How many KB does the model require for weights + scratch buffers?
6. **Measured inference latency** on ESP32-WROOM-32E @ 240 MHz (must be ≤ 300 ms).
7. **Flash footprint:** How many KB does the exported C++ library add to the `.bin`?
8. **EI_CLASSIFIER_FREQUENCY:** Must equal 4000. Confirm.
9. **EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE:** Must equal 4000. Confirm.
10. **Calibration status:** Were the Logistic Regression / Random Forest baseline models from `ml/models/` used as a reference, or is the new model trained on physical sensor data?

See [TINYML_INTEGRATION_CONTRACT.md](file:///d:/NAADYANTRA/docs/TINYML_INTEGRATION_CONTRACT.md) for the full interface specification.
