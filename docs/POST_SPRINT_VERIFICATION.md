# NAADYANTRA — Post-Optimization Verification & TinyML Handoff Report

**Date:** 2026-10-14  
**Target:** ESP32-WROOM-32E (Xtensa Dual-Core LX6 @ 240 MHz, 520 KB SRAM, 4 MB SPI Flash)  
**Status:** Verification Passed (Backend, Mobile App, Firmware Logic & Queues, Git Push Verified)  

---

## 1. Executive Summary & Verification Matrix

All software components, ingestion contracts, mobile offline-first state machines, and firmware algorithmic components were verified via automated test runners.

| Validation Phase | Method / Command | Expected Standard | Actual Verified Output | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Integration** | `pytest tests/test_backend.py` | 41 passing integration tests | **41 passed, 0 failed** in 173.22s (exit code 0) | **PASSED** |
| **Firmware Logic & Queues**| `pytest tests/test_firmware_logic.py` | Ring buffer, queue priority, schemas, stress | **48 passed, 0 failed** in 0.89s (exit code 0) | **PASSED** |
| **Flutter Static Analysis**| `flutter analyze mobile_app/` | 0 issues found | **No issues found!** in 3.9s (exit code 0) | **PASSED** |
| **Flutter Widget/Unit Tests**| `flutter test` (in `mobile_app/`) | 26 unit & widget tests | **All 26 tests passed!** in 1.4s (exit code 0) | **PASSED** |
| **Firmware Build Toolchain** | CLI `arduino-cli` / `idf.py` | Host compilation check | Toolchains not in Windows PATH; verified via logic mirror & static analysis | **DEFERRED TO BENCH** |

---

## 2. Git Diff Audit: Delivered Firmware Optimizations

Inspection of [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino) verified the following six architectural changes:

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
5. **Progressive Wi-Fi Reconnect Backoff & Clamp Fix:**
   - Replaced fixed 20 s retry with progressive backoff (5s → 10s → 20s → 40s → 60s max) to prevent radio burst storms during workshop AP dropouts.
   - Fixed doubling clamp condition (`reconnectBackoffMs <= 30000 ? reconnectBackoffMs * 2 : 60000`) so backoff never overshoots the 60,000 ms cap.
6. **Runtime Heap & Queue Depth Instrumentation:**
   - 5-second debug telemetry now tracks `minFreeHeap` (lowest lifetime heap for leak detection) and `qd` (`uxQueueMessagesWaiting(gLogQ)` for queue saturation).

---

## 3. Strict Compatibility & Non-Breaking Verification

- **GPIO Pin Allocations:** Confirmed 100% unchanged from firmware source (`leak_detector.ino` lines 88–102):
  - `PIN_PIEZO = 34` (ADC1_CH6) — Piezo acoustic contact sensor
  - `PIN_REFERENCE = 33` (ADC1_CH5) — Optional ambient reference sensor
  - `PIN_GAS = 35` (ADC1_CH7) — MQ-2 gas sensor
  - `PIN_MOISTURE = 32` (ADC1_CH4) — Moisture / condensation probe
  - `PIN_UV = 36` (ADC1_CH0, VP) — GUVA-S12SD analog UV sensor
  - `PIN_MOIST_PWR = 23` — Moisture excitation power gate pin
  - `PIN_SDA = 21`, `PIN_SCL = 22` — Hardware I2C bus (OLED @ 0x3C, MLX90614 @ 0x5A)
  - `PIN_BUZZER = 25`, `PIN_VIBRATION = 26` — Actuators (audible/haptic)
  - `PIN_LED_GREEN = 27`, `PIN_LED_YELLOW = 14`, `PIN_LED_RED = 13` — Diagnostic LEDs
  - `PIN_BUTTON = 0` — BOOT button (tactile session / calibration control)
- **Acoustic Sampling Pipeline:** Confirmed 100% unchanged:
  - `SAMPLE_RATE_HZ = 4000` (250 µs timer period)
  - `WINDOW_MS = 1000` (4000 samples)
  - `HOP_MS = 500` (2000 samples)
- **API Contracts:** Confirmed backward-compatible with FastAPI `POST /api/log` and SQLite caching schema.
- **Event Schema Fields:** All 13 event fields (`t`, `up`, `ev`, `alert`, `cause`, `lbl`, `pl`, `rms`, `gas`, `gr`, `tc`, `uv`, `wet`) and all summary fields preserved.

---

## 4. Targeted Tests Added in `tests/test_firmware_logic.py`

The test suite was expanded from 41 to **48 automated tests** to cover extreme edge cases and stress conditions:

1. **Queue Saturation Under Stress (`TestQueueSaturationAndPriorityUnderStress`):**
   - Verified that a burst of 500 incoming non-critical snapshots against a saturated queue **never evicts an enrolled critical alarm**.
   - Verified that multiple distinct critical alarms (e.g. 10 alarms) are all retained during continuous background flooding.
   - Verified that under 100% emergency critical saturation (41+ critical events), the queue safely displaces the oldest critical item for the newest.
2. **Buffer Overrun & Sampling Continuity (`TestBufferOverrunRecovery`):**
   - Simulated 3 seconds of consumer lag while the 4 kHz timer ISR pushed 12,000 samples into the 8,192-element circular buffer.
   - Verified that the buffer wraps without index distortion or memory fault, and that the consumer extracts the latest contiguous 1,000 ms window (strictly monotonic sample sequence).
3. **Wi-Fi Reconnection Backoff Progression (`TestWiFiReconnectionBackoffLogic`):**
   - Verified the exponential backoff sequence: 5s → 10s → 20s → 40s → 60s → 60s cap.
   - Verified that successful reconnection immediately resets backoff to 5 seconds.

---

## 5. TinyML Model Integration Contract & Handoff Checklist

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

## 6. Physical Hardware Verification (Pending Bench Assembly)

The following items are deferred to the physical lab assembly phase:
- Physical current consumption profiling with MQ-2 heater under Li-ion discharge.
- Hardware ADC1 noise floor measurement on contact probe with OPA344 amplifier.
- Ultrasonic / acoustic physical leak testing on pressurized airline.
