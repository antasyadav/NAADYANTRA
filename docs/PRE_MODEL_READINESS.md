# NAADYANTRA — Final Pre-Model Readiness & Verification Check

**Document Version:** 1.0.0  
**Date:** 2026-10-14  
**Target Hardware:** ESP32-WROOM-32E (Xtensa Dual-Core LX6 @ 240 MHz, 520 KB SRAM, 4 MB Flash)  
**Status:** Pre-Model Audit Complete — Fallback Active — Awaiting Physical Model Artifact  

---

## 1. Resolution of Firmware Build Status & Claims

To eliminate ambiguity across previous documentation, the build verification status is formally categorized into three distinct levels:

| Verification Level | Scope & Method | Actual Measured Status | Evidence / Notes |
| :--- | :--- | :--- | :--- |
| **1. Source-Level Review & Syntax Check** | C/C++ structural audit of [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino) | **PASSED (Unblocked)** | Setting `#define USE_EDGE_IMPULSE 0` eliminates the `#include <YOUR_PROJECT_inferencing.h>` missing-header blocker. Code uses standard Arduino-ESP32 core APIs, FreeRTOS primitives, and STL atomics. |
| **2. Host Algorithmic & Regression Tests** | `pytest tests/test_firmware_logic.py` (Python 3.11 on host) | **PASSED (48/48 tests)** | Validates 32-bit atomic ring-buffer pointer arithmetic, power-of-two circular wrap, queue eviction priority, backoff clamping, and JSON schemas. |
| **3. Target ESP32 Firmware Compilation** | Invocation of `xtensa-esp32-elf-g++` via `arduino-cli` or ESP-IDF | **DEFERRED (Toolchain Unavailable on Host)** | Neither `arduino-cli` nor `idf.py` is installed in the Windows system PATH. Generating an actual `.bin` image requires testing on a machine with the ESP32 Arduino core installed. |

> [!IMPORTANT]
> **Honest Engineering Grounding:**  
> The term *"verified buildable out-of-the-box"* previously used in sprint notes refers strictly to **Level 1 (source-level unblocking)**: all proprietary and missing external dependencies have been conditionally gated out so the source tree has no missing headers.  
> **Level 3 (real target compilation to machine binary)** has **NOT** been performed on this host environment and remains **DEFERRED TO PHYSICAL BENCH ASSEMBLY**.

---

## 2. Edge Impulse Input Contract & Macro Validation

The intended model input is a **4,000-sample raw time-domain audio waveform at 4,000 Hz**. However, the firmware and model adapter must strictly validate the teammate's exported C++ library macros before allowing compilation or runtime execution.

### Edge Impulse Macro Semantics
In an Edge Impulse C++ library export, metadata macros are generated inside `model-parameters/model_metadata.h`. These macros are **not guaranteed to be identical**:

| Macro Name | Semantic Meaning | Expected Value for NAADYANTRA | Risk if Mismatched |
| :--- | :--- | :--- | :--- |
| `EI_CLASSIFIER_RAW_SAMPLE_COUNT` | Number of time-series samples per channel | **4000** | If $< 4000$ (e.g. 2000 for a 500ms window), frame slicing is required. |
| `EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME` | Number of axes / channels per time-step | **1** | Firmware samples a single-axis contact piezo. If $> 1$ (e.g. 3 for tri-axial accelerometer), model expects interleaved channels that do not exist. |
| `EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE` | Total number of floats passed to the DSP block | **4000** | Must equal $\text{RAW\_SAMPLE\_COUNT} \times \text{RAW\_SAMPLES\_PER\_FRAME}$. |
| `EI_CLASSIFIER_FREQUENCY` | Expected sampling rate in Hz | **4000** | If different (e.g. 16000), physical timer sampling at 4000 Hz will cause acoustic spectral compression / frequency shifting. |
| `EI_CLASSIFIER_LABEL_COUNT` | Total number of output classes | **3** | Must match operational roles (`normal`, `leak`, `noise`). |

### Documented `signal_t` Usage in Firmware
In [leak_detector.ino](file:///d:/NAADYANTRA/leak_detector.ino#L563-L568):
```cpp
#if USE_EDGE_IMPULSE
  signal_t sig;
  if (numpy::signal_from_buffer(x, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &sig) != 0) return;
  ei_impulse_result_t res = { 0 };
  const uint32_t t0 = millis();
  if (run_classifier(&sig, &res, false) != EI_IMPULSE_OK) return;
```
`numpy::signal_from_buffer` constructs an Edge Impulse `signal_t` wrapper referencing a contiguous `float*` buffer of length `EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE`.

### Safe Adapter Rejection Guardrails
When `#define USE_EDGE_IMPULSE 1` is enabled, the model adapter (`model_adapter.h` / firmware compile-time check) must enforce the following preprocessor assertions:

```cpp
#if USE_EDGE_IMPULSE
  #if (EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME != 1)
    #error "Model rejection: NAADYANTRA firmware only samples 1 piezo channel (EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME must be 1)."
  #endif

  #if (EI_CLASSIFIER_FREQUENCY != 4000)
    #error "Model rejection: Sampling frequency mismatch. Firmware timer runs at 4000 Hz (EI_CLASSIFIER_FREQUENCY must be 4000)."
  #endif

  #if (EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE != 4000)
    #error "Model rejection: Buffer size mismatch with gFeat[4000] (EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE must be 4000)."
  #endif

  #if (EI_CLASSIFIER_LABEL_COUNT != 3)
    #error "Model rejection: Output class count mismatch. Firmware requires exactly 3 classes: normal, leak, noise."
  #endif
#endif
```

If an incoming model violates any of these parameters, it is **rejected at compile-time**, preventing silent memory corruptions, buffer out-of-bounds reads, or acoustic timing mismatches.

---

## 3. Firmware ADC Representation & Model Preprocessing Alignment

To prevent catastrophic train-serve skew between offline Python/Edge Impulse training and embedded ESP32 execution, the exact sample representation is confirmed below:

```
[Piezo Contact Sensor + OPA344 Pre-Amp]
                  |
                  v
       Analog In: PIN_PIEZO (GPIO 34, ADC1_CH6)
                  |
                  v
       analogRead(PIN_PIEZO) -> 12-bit unsigned ADC counts (0 to 4095)
       Hardware attenuation: ADC_11db (Full-scale ~3.3V)
       Virtual ground center: ~1.65V (~2048 counts)
                  |
                  v
       DcBlock::step(): y[n] = x[n] - x[n-1] + 0.995 * y[n-1]
                  |
                  v
       clamp16(y): Stored in circular gRing as signed int16_t (-2048 to +2047 nominal)
                  |
                  v
       gFeat[i] = (float)gRing[i]: Snapshot of 4000 float32 samples
                  |
                  v
       numpy::signal_from_buffer(gFeat, 4000, &sig) -> Passed to Edge Impulse DSP Block
```

### Preprocessing Specifications Matrix
| Parameter | Value in Firmware | Value Expected by Model |
| :--- | :--- | :--- |
| **Input Signal Representation** | Centered ADC counts (signed, zero-mean) | Centered ADC counts (signed, zero-mean) |
| **Numeric Data Type** | `float32` (IEEE 754 single-precision) | `float32` array |
| **Nominal Signal Range** | Approximately $-2048.0$ to $+2047.0$ | Approximately $-2048.0$ to $+2047.0$ |
| **High-Pass Filter** | First-order IIR DC-block filter ($R = 0.995$) | Must match $R = 0.995$ filter |
| **Firmware Normalization** | **None** (zero pre-scaling or z-score in C) | Internal DSP block handles scaling |
| **Input Frame Length** | Exactly 4,000 samples ($1000\text{ ms}$ @ $4\text{ kHz}$) | Exactly 4,000 samples |
| **Output Label Order** | `[0: "normal", 1: "leak", 2: "noise"]` | `[0: "normal", 1: "leak", 2: "noise"]` |

---

## 4. Preservation of Fallback Mechanism

The deterministic fallback detector is **preserved as the active implementation**:
- `leak_detector.ino` maintains `#define USE_EDGE_IMPULSE 0`.
- The fallback algorithm computes the energy ratio between the current window RMS and the calibrated baseline RMS:
  $$R_{\text{RMS}} = \frac{\text{RMS}_{\text{window}}}{\text{RMS}_{\text{baseline}}}$$
  $$\text{pLeak} = \text{clamp}\left(\frac{R_{\text{RMS}} - 1.0}{3.0 - 1.0},\ 0.0,\ 1.0\right)$$
- If $\text{pLeak} \ge 0.65$ for 2 consecutive windows, `ROLE_LEAK` is asserted.
- The telemetry label emitted is `"leak(rms)"` or `"no_leak(rms)"`, preventing any operator confusion with machine learning inference.
- **Rule:** Under no circumstance will synthetic or fabricated predictions be hardcoded to simulate model execution. The fallback remains active until real model headers and binaries are provided.

---

## 5. Web Dashboard Verification Record

- **Audit Finding:** A comprehensive filesystem scan of `d:\NAADYANTRA` confirms that **no web dashboard application exists** in the repository.
- **Active Codebases:**
  - `backend/`: FastAPI REST API server with OpenAPI docs at `/docs`.
  - `mobile_app/`: Flutter mobile application (Android / iOS / Desktop).
  - `ml/`: Offline Python data collection, preprocessing, and training prototypes.
  - `tests/`: Pytest integration and logic test suites.
- **Truthfulness Standard:** No claims of web dashboard testing, rendering, or integration will be made unless a web frontend codebase is introduced and verified.

---

## 6. Teammate Handoff Checklist & Required Deliverables

When the teammate delivers the acoustic TinyML model, they must supply the following exact artifacts and verified metadata:

```
[ ] 1. MODEL ARTIFACT ARCHIVE
       - Edge Impulse C++ library export (.zip archive containing edge-impulse-sdk/,
         model-parameters/, and tflite-model/)
       - OR flat C byte array (model_data.h) with confirmed TFLite Micro runtime.

[ ] 2. HEADER METADATA PROOF (from model-parameters/model_metadata.h)
       - EI_CLASSIFIER_RAW_SAMPLE_COUNT == 4000
       - EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME == 1
       - EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE == 4000
       - EI_CLASSIFIER_FREQUENCY == 4000
       - EI_CLASSIFIER_LABEL_COUNT == 3

[ ] 3. OUTPUT CLASS MAPPING CONFIRMATION
       - Index 0: "normal"
       - Index 1: "leak"
       - Index 2: "noise"

[ ] 4. BENCH RESOURCE MEASUREMENTS (Measured on ESP32-WROOM-32E @ 240 MHz)
       - Tensor Arena RAM: ______ KB (Target <= 32 KB, Hard Limit <= 60 KB)
       - Flash Binary Contribution: ______ KB (Target <= 350 KB, Hard Limit <= 550 KB)
       - Inference Latency: ______ ms (Target <= 300 ms, Peak <= 420 ms under Wi-Fi load)

[ ] 5. SCORE CALIBRATION DISCLOSURE
       - Are scores uncalibrated Softmax or temperature-scaled?
       - If calibrated, provide temperature scaling parameter T: ______

[ ] 6. TRAINING DATASET PROVENANCE DISCLOSURE
       - Was training performed on synthetic signals (generate_synthetic.py)
         or physical acoustic pipe recordings?
       - If physical: Pipe material, diameter, pressure range, and noise conditions.
```

---

## 7. Next Steps

1. Teammate completes and returns the Handoff Checklist above along with the C++ model archive.
2. Verify headers against preprocessor safety guards.
3. Place model files in `mobile_app/` or Arduino `libraries/` directory.
4. Set `#define USE_EDGE_IMPULSE 1` in `leak_detector.ino`.
5. Execute target build using `arduino-cli compile` on the bench workstation.
