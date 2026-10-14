# NAADYANTRA — Post-Optimization Verification & TinyML Handoff Report

**Date:** 2026-10-14  
**Target:** ESP32-WROOM-32E (Xtensa Dual-Core LX6 @ 240 MHz, 520 KB SRAM, 4 MB Flash)  
**Status:** Verification Passed (Software, Backend, Flutter, Firmware Logic)  

---

## 1. Executive Summary & Verification Matrix

| Validation Phase | Method / Tool | Expected / Standard | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Integration** | `pytest tests/test_backend.py` | 41 passing integration tests | **41 passed** in 173.22s | **PASSED** |
| **Firmware Logic & Queues**| `pytest tests/test_firmware_logic.py` | Ring buffer, queue priority, schemas | **41 passed** in 0.86s | **PASSED** |
| **Flutter Static Analysis**| `flutter analyze mobile_app/` | 0 issues found | **0 issues found** | **PASSED** |
| **Flutter Widget/Unit Tests**| `flutter test mobile_app/` | 26 unit & widget tests | **26 passed** | **PASSED** |
| **Firmware Build Toolchain** | CLI `arduino-cli` / `idf.py` | Host compilation check | Not in system PATH; verified via logic mirror & static analysis | **DEFERRED TO BENCH** |

---

## 2. Git Diff Audit: Delivered Firmware Optimizations

Inspection of [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino) verified the following exact changes:

1. **`USE_EDGE_IMPULSE = 0` Fallback Configuration:**
   - Switched from non-compilable `#define USE_EDGE_IMPULSE 1` (missing external library) to `0`.
   - Out-of-the-box build uses the verified RMS-to-baseline ratio fallback detector.
2. **Priority-Aware Telemetry Queue:**
   - `LogItem` struct updated with `bool critical`.
   - `enqueueLog()` protects critical events (`ALERT_DANGER`, `session_start`, `session_stop`, summary) from being dropped when saturated by routine 5-second `snap` telemetry.
3. **Redundant 16 KB Float Copy Removed:**
   - When running under RMS fallback (`USE_EDGE_IMPULSE == 0`), `inferenceStep()` computes energy directly from the `int16_t` circular buffer via `ringRms()`.
   - Skips unnecessary 16 KB `float` write cycle every 500 ms on Core 0.
4. **OLED Throttling & State-Aware Refresh:**
   - Throttled base refresh from 250 ms to 500 ms, halving 100 kHz I2C bus congestion.
   - Fast-path refresh (100 ms) preserved when `alert` or `cause` state transitions occur.
5. **Progressive Wi-Fi Reconnect Backoff:**
   - Replaced fixed 20 s retry with progressive backoff (5s → 10s → 20s → 40s → 60s max) to prevent radio burst storms during workshop AP dropouts.
6. **Runtime Heap & Queue Depth Instrumentation:**
   - 5-second debug telemetry now tracks `minFreeHeap` (lowest lifetime heap for leak detection) and `qd` (`uxQueueMessagesWaiting(gLogQ)` for queue saturation).

---

## 3. Strict Compatibility & Non-Breaking Verification

- **GPIO Pin Allocations:** Confirmed 100% unchanged (`PIN_PIEZO = 34`, `PIN_GAS = 35`, `PIN_UV = 32`, `PIN_MOISTURE = 33`, `PIN_SDA = 21`, `PIN_SCL = 22`).
- **Acoustic Sampling Pipeline:** Confirmed 100% unchanged (`SAMPLE_RATE_HZ = 4000`, `WINDOW_MS = 1000`, `HOP_MS = 500`).
- **API Contracts:** Confirmed backward-compatible with FastAPI `POST /api/log` and SQLite caching schema.
- **Event Schema Fields:** All 13 event fields (`t`, `up`, `ev`, `alert`, `cause`, `lbl`, `pl`, `rms`, `gas`, `gr`, `tc`, `uv`, `wet`) and summary fields preserved.

---

## 4. TinyML Model Integration Contract & Handoff

The binding specification is documented in [docs/TINYML_INTEGRATION_CONTRACT.md](file:///d:/NAADYANTRA/docs/TINYML_INTEGRATION_CONTRACT.md).

### Files Required from Teammate:
1. **Model Artifact:** Edge Impulse C++ library export (`.zip`) containing `<project_name>_inferencing.h` OR TFLite flat byte array (`model_data.h`).
2. **Feature Scaler:** Mean ($\mu$) and standard deviation ($\sigma$) array if feature-based.
3. **Class Mapping:** Output vector must match: `[0: "normal", 1: "leak", 2: "noise"]`.
4. **Bench Metrics:** Confirmed execution latency $\le 300\text{ ms}$ on ESP32 @ 240 MHz and RAM arena $\le 60\text{ KB}$.

### Next Steps Upon Model Arrival:
1. Extract model archive into Arduino `libraries/` directory.
2. In [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino), change `#define USE_EDGE_IMPULSE 0` to `1`.
3. Flash device, attach acoustic probe to test pipe, and observe inference latency on serial monitor.

---

## 5. Physical Hardware Verification (Pending Bench Assembly)

The following items are deferred to the physical lab assembly phase:
- Physical current consumption profiling with MQ-2 heater under Li-ion discharge.
- Hardware ADC1 noise floor measurement on contact probe.
- Ultrasonic / acoustic physical leak testing on pressurized airline.
