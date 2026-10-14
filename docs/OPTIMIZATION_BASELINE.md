# NAADYANTRA — Optimization Baseline & Technical Audit

**Date:** 2026-10-14  
**Workspace:** `d:\NAADYANTRA`  
**Purpose:** Comprehensive baseline audit of firmware, signal processing, backend, mobile application, power budget, and memory architecture before sprint optimization.

---

## 1. Verified Target Hardware & Board Configuration

- **Target Board:** **ESP32-WROOM-32E** (Xtensa dual-core LX6 @ 240 MHz, 520 KB SRAM, 4 MB external SPI flash).
- **Physical Verification:**
  - In [leak_detector.ino:L71-L103](file:///d:/NAADYANTRA/leak_detector.ino#L71-L103), while an `#if CONFIG_IDF_TARGET_ESP32S3` preprocessor branch exists, the `#else` branch maps explicitly to the classic ESP32 pinout (`PIN_PIEZO = 34`, `PIN_GAS = 35`, `PIN_UV = 36`, `PIN_MOISTURE = 32`, `PIN_SDA = 21`, `PIN_SCL = 22`).
  - Pins 34, 35, and 36 are input-only GPIOs unique to the original ESP32 / WROOM-32 silicon (non-existent on ESP32-S3).
- **ADC Routing Verification:**
  - All analog sensors (`PIN_PIEZO`, `PIN_GAS`, `PIN_UV`, `PIN_MOISTURE`) are wired strictly to **ADC1** (`ADC1_CH6`, `ADC1_CH7`, `ADC1_CH0`, `ADC1_CH4`).
  - **Silicon Reality:** On the ESP32, Wi-Fi monopolizes **ADC2**. Because zero sensors use ADC2, **Wi-Fi radio transmissions do not collide with or block analog sensor sampling**.

| Signal Name | Physical GPIO | Peripheral / Channel | Type / Direction | Hardware Notes |
| :--- | :--- | :--- | :--- | :--- |
| `PIN_PIEZO` | GPIO 34 | ADC1_CH6 | Analog In (Input only) | Requires virtual ground bias (~1.65V) & OPA344 amp |
| `PIN_GAS` | GPIO 35 | ADC1_CH7 | Analog In (Input only) | MQ-2 output via 10k/20k resistor divider to 3.3V |
| `PIN_UV` | GPIO 36 | ADC1_CH0 (VP) | Analog In (Input only) | GUVA-S12SD analog UV sensor |
| `PIN_MOISTURE`| GPIO 32 | ADC1_CH4 | Analog In | Soil / pipe condensation probe |
| `PIN_MOIST_PWR`| GPIO 23 | Digital Output | Output | Gated excitation rail to prevent probe electrolysis |
| `PIN_SDA` | GPIO 21 | I2C SDA | Bidirectional | 100 kHz clock, shared by SSD1306, MLX90614, VL53L0X |
| `PIN_SCL` | GPIO 22 | I2C SCL | Bidirectional | 100 kHz clock, 4.7k pull-ups |
| `PIN_BUZZER` | GPIO 25 | Digital Output (DAC1)| Output | Drives active 5V buzzer via transistor/direct |
| `PIN_VIBRATION`| GPIO 26 | Digital Output (DAC2)| Output | Haptic eccentric rotating mass (ERM) motor |
| `PIN_LED_GREEN`| GPIO 27 | Digital Output | Output | Status OK indicator |
| `PIN_LED_YELLOW`| GPIO 14 | Digital Output (MTMS)| Output | Status CAUTION indicator (strapping pin on boot) |
| `PIN_LED_RED` | GPIO 13 | Digital Output (MTCK)| Output | Status DANGER indicator |
| `PIN_BUTTON` | GPIO 0 | Digital Input (BOOT) | Input (Pullup) | Short press: session start/stop; Long press (>2s): cal |

---

## 2. Firmware Signal Processing & Task Architecture

### Sampling Pipeline
- **Sampling Rate (`SAMPLE_RATE_HZ`):** 4000 Hz.
- **Window Length (`WINDOW_MS`):** 1000 ms (4000 samples).
- **Hop Interval (`HOP_MS`):** 500 ms (2000 samples, 50% overlap).
- **Ring Buffer Allocation:** $2^{13} = 8192$ elements (power-of-two mask wrapping), allocated once via `calloc` at boot ($16.38\text{ KB}$).
- **DC-Block Filter:** First-order IIR $y[n] = x[n] - x[n-1] + R \cdot y[n-1]$ with $R = 0.995$.
- **Bandwidth Constraint (Physics):** Nyquist frequency is $f_s / 2 = 2000\text{ Hz}$. The system captures acoustic flow hiss, mechanical vibration, and audible cavitation, **not ultrasonic** (25–40 kHz) frequencies.

### FreeRTOS Tasks & Core Distribution

| Task Name | Core | Priority | Stack Size | Trigger / Frequency | Function |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sampler` | Core 1 | 10 (High) | 4096 bytes | Hardware Timer ISR @ 4 kHz | Non-blocking `analogRead` + DC-block into `gRing` |
| `infer` | Core 0 | 2 (Normal) | 16384 bytes | Task Notification on hop (2 Hz) | Window copy, RMS / feature calculation, role verdict |
| `upload` | Core 0 | 1 (Low) | 16384 bytes | FreeRTOS Queue `gLogQ` | Wi-Fi HTTP POST to `POST /api/log` with retry |
| `loopTask` | Core 1 | 1 (Low) | 8192 bytes | Continuous loop (5ms delay) | Button debounce, slow sensors, OLED, buzzer cadence |

### Sensor Compile-Time Flags Status

```cpp
#define USE_EDGE_IMPULSE      1   // Fails build: points to placeholder <YOUR_PROJECT_inferencing.h>
#define USE_REFERENCE_SENSOR  0   // Dual mic disabled
#define HAS_GAS_SENSOR        1   // MQ-2 enabled
#define HAS_MOISTURE_SENSOR   1   // Conduction probe enabled
#define HAS_HEAT_SENSOR       0   // MLX90614 disabled in config
#define HAS_UV_SENSOR         0   // GUVA-S12SD disabled in config
#define MOIST_POWER_GATED     1   // Gated excitation enabled
#define ENABLE_WIFI_LOGGING   1   // Wi-Fi HTTP upload enabled
#define BUZZER_PASSIVE        0   // Active 5V buzzer mode
```

---

## 3. TinyML & Machine Learning Current State

1. **Compilation Blocker:** In [leak_detector.ino:L167](file:///d:/NAADYANTRA/leak_detector.ino#L167), `#include <YOUR_PROJECT_inferencing.h>` is a non-existent placeholder. Compiling with `USE_EDGE_IMPULSE == 1` causes immediate build failure.
2. **Offline Models:**
   - In `ml/models/logistic_regression_baseline/` and `ml/models/random_forest_baseline/`:
     - Metadata explicitly confirms: `"data_source": "synthetic"`.
     - Models were trained purely on synthetic mathematical noise, with 0 genuine acoustic samples from physical pipe setups.
3. **Features Implemented in Python (`ml/src/preprocessing.py`):**
   - 9 features: `rms`, `std`, `peak_amplitude`, `crest_factor`, `zero_crossing_rate`, `band_energy_0_500`, `band_energy_500_1000`, `band_energy_1000_2000`, `total_energy`.
4. **Fallback Detector in Firmware:**
   - [leak_detector.ino:L580-L590](file:///d:/NAADYANTRA/leak_detector.ino#L580-L590) implements an RMS ratio fallback detector (`r.rms / base`), but it is dead code while `USE_EDGE_IMPULSE == 1`.

---

## 4. Backend & Mobile Application Status

### FastAPI Backend (`backend/`)
- **Ingestion Endpoint:** `POST /api/log` with query parameters `?trainee={id}&session={id}&kind={event|summary}`.
- **Authentication:** `X-Device-Key` header verified against Argon2/bcrypt password hash or global device key.
- **Payload Schema:**
  - `t` (epoch timestamp), `up` (uptime ms), `ev` (event name), `alert` (OK, CAUTION, DANGER), `cause` (LEAK, GAS_ALARM, etc.), `lbl` (label), `pl` (leak probability), `rms`, `gas`, `gr`, `tc`, `uv`, `wet`, `device`, `fw`.
- **Database & Idempotency:** SQLite database (`hazguard.db`), Alembic migrations, idempotency hash calculated from device, session, kind, and payload to discard duplicates.
- **Test Baseline:** `pytest tests/test_backend.py` -> **41 passed, 0 failed** in 178s.

### Flutter Mobile App (`mobile_app/`)
- **Framework:** Flutter 3.47.2 / Dart 3.13.2.
- **Architecture:** Riverpod 2.6, GoRouter 14, Dio 5.7, Sqflite local persistent cache.
- **Design System:** Cinematic light industrial palette (Industrial Ivory `#F7F5F0`, Carbon `#252525`, Burnt Orange `#F07842`).
- **Static Analysis:** `flutter analyze` -> **No issues found (0 warnings, 0 errors)** in 33.3s.
- **Widget & Unit Tests:** `flutter test` -> **26 passed, 0 failed** in 1.4s.

### Web Dashboard Audit
- **Verification:** Searched complete accessible workspace for `package.json`, web dashboards, Vite, React, or Next.js projects.
- **Finding:** **No separate web dashboard exists** in the accessible repository. System monitoring is handled exclusively via the Flutter application and FastAPI swagger docs (`/docs`).

---

## 5. Identified Inefficiencies & Optimization Targets

| Area | Current Implementation Issue | Risk / Bottleneck | Optimization Target |
| :--- | :--- | :--- | :--- |
| **Firmware Build** | `#define USE_EDGE_IMPULSE 1` with missing `<YOUR_PROJECT_inferencing.h>` | Firmware cannot be compiled by anyone out of the box | Provide buildable TinyML adapter interface with clean fallback to RMS/feature rules |
| **Queue Overflow** | `enqueueLog()` blindly drops oldest queue item on overflow | Critical `session_start` or `GAS_ALARM` can be discarded to save a routine 5-second `snap` | Prioritized queue retention: drop routine snapshots before dropping critical alarms |
| **OLED I2C Bus Load** | `refreshDisplay()` refreshes every 250 ms (4 Hz) transferring 1024-byte framebuffer | At 100 kHz I2C, each transfer takes ~100 ms (40% bus utilization) | Throttle display to 500 ms (2 Hz) unless alert changes state; avoid redrawing identical content |
| **Inference Copy Overhead** | `inferenceStep()` converts 4000 int16 samples to float in `gFeat` even when running rule detector | 4000 float conversions every 500 ms on Core 0 | Compute RMS directly from `gRing` via `ringRms()` when TinyML model is absent |
| **Instrumentation** | No tracking of minimum free heap, queue watermark, or task stack watermarks | Silent out-of-memory or stack overflow during extended runtime | Add instrumentation for `ESP.getMinFreeHeap()`, `uxTaskGetStackHighWaterMark()`, and queue depth |
| **Power Management** | Wi-Fi reconnect attempts every 20s with aggressive 500ms delay | Wastes battery on continuous station retries | Implement progressive backoff on Wi-Fi connection loss |
