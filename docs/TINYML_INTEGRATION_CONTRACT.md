# NAADYANTRA — TinyML Model Integration Contract

**Document Version:** 1.0.0  
**Target Architecture:** ESP32-WROOM-32E (Xtensa Dual-Core LX6 @ 240 MHz, 520 KB SRAM, 4 MB SPI Flash)  
**Intended Audience:** ML / TinyML Engineer preparing the acoustic leak classification model for NAADYANTRA.

---

## 1. Executive Summary & Purpose

This document defines the strict, binding integration interface for the acoustic machine learning model to be deployed onto the NAADYANTRA ESP32-WROOM-32E firmware.

The firmware architecture maintains a **dual-path design**:
1. **Model Path (When Available):** Invokes the exported model via the C++ adapter interface.
2. **Deterministic Fallback Path (Active by Default):** Executes the verified physical RMS-to-baseline and crest-factor rule detector if the model is absent, uninitialized, or fails inference.

---

## 2. Signal Pipeline & Input Specification

The firmware acquisition pipeline runs on **Core 1** inside a hardware timer interrupt and FreeRTOS task. The model is invoked on **Core 0** inside `inferTask`.

| Specification Parameter | Required Value | Firmware Reference | Notes |
| :--- | :--- | :--- | :--- |
| **Physical Sensor** | Piezoelectric Disc 27mm + OPA344UA Amp | `PIN_PIEZO = 34` (ADC1_CH6) | Contact acoustic vibration |
| **Sampling Rate ($f_s$)** | **4000 Hz** ($\pm 10\text{ Hz}$) | `SAMPLE_RATE_HZ = 4000` | Hardware timer period: $250\ \mu\text{s}$ |
| **Window Duration** | **1000 ms** | `WINDOW_MS = 1000` | Exactly 4000 raw samples |
| **Hop Interval** | **500 ms** (50% overlap) | `HOP_MS = 500` | Exactly 2000 samples |
| **Nyquist Limit** | **2000 Hz** | Theoretical | Captures structural audio/hiss, NOT ultrasound |
| **Preprocessing Filter** | First-Order IIR DC-Block Filter | $y[n] = x[n] - x[n-1] + 0.995 \cdot y[n-1]$ | Removes ~1.65V virtual ground offset |
| **Input Data Format** | `int16_t` in circular ring buffer; converted to `float` buffer `gFeat` | `gFeat` array of length 4000 | Values normalized to centered ADC units |

---

## 3. Supported Model Artifact Formats & Runtimes

The teammate may deliver the model in either of the two standard embedded formats:

### Format A: Edge Impulse C++ Export (Recommended)
- **Archive Contents:** ZIP archive exported from Edge Impulse Studio (`C++ Library`).
- **Target Folder:** Extracted directly into Arduino/ESP-IDF libraries folder or as `src/model/`.
- **Top-Level Header:** `<project_name>_inferencing.h`.
- **Requirements:**
  - `EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME == 1` (Single-axis acoustic piezo).
  - `EI_CLASSIFIER_FREQUENCY == 4000` (4 kHz sampling rate).
  - `EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE == 4000` (1-second window).
  - Tensor arena RAM requirement: $\le 60\text{ KB}$.
  - Flash footprint: $\le 500\text{ KB}$.

### Format B: TensorFlow Lite for Microcontrollers (TFLite Micro) or Static C Array
- **Artifact:** Flat C/C++ byte array (`const unsigned char model_data[]`) generated via `xxd -i model.tflite model_data.h`.
- **Quantization:** Fully quantized INT8 or Float32.
- **Tensor Arena:** Allocated statically or via `heap_caps_malloc(arena_size, MALLOC_CAP_8BIT)` with $\text{arena} \le 50\text{ KB}$.

---

## 4. Input & Output Tensor Semantics

### Input Tensor
- **Shape:** `[1, 4000]` for raw waveform OR `[1, N_features]` for handcrafted feature array.
- **Normalization:** If features are used, provide exact mean $\mu$ and scale $\sigma$ vectors matching [ml/src/preprocessing.py](file:///d:/NAADYANTRA/ml/src/preprocessing.py):
  1. `rms`
  2. `std`
  3. `peak_amplitude`
  4. `crest_factor`
  5. `zero_crossing_rate`
  6. `band_energy_0_500`
  7. `band_energy_500_1000`
  8. `band_energy_1000_2000`
  9. `total_energy`

### Output Classes & Label Ordering
The model must output a probability distribution across 3 distinct operational classes:

```
Index 0: "normal"     (Laminar pipe flow, quiet background, nominal state)
Index 1: "leak"       (Turbulent orifice leak, pressurized air/gas hissing)
Index 2: "noise"      (Workshop machinery, foot traffic, ambient speech, metal strikes)
```

### Probability Semantics
- Model scores must be calibrated probabilities between `0.0` and `1.0` (Softmax output summing to 1.0).
- If uncalibrated logits are returned, the teammate must provide temperature scaling factors.
- **Do not label raw heuristic scores as model probabilities.**

---

## 5. Execution Budget & Hardware Constraints

On the ESP32-WROOM-32E (Xtensa LX6 @ 240 MHz):

1. **Inference Latency Limit:** $\le 300\text{ ms}$ per window.
   - *Rationale:* New windows arrive every $500\text{ ms}$ (`HOP_MS = 500`). An inference latency under 300 ms guarantees a 40% margin on Core 0, preventing queue saturation and buffer overruns.
2. **RAM Allocation Limit:** $\le 64\text{ KB}$ peak SRAM.
   - *Rationale:* The firmware already utilizes $\sim 105\text{ KB}$ of SRAM for ring buffers, FreeRTOS task stacks, display framebuffers, and telemetry queues. Remaining free heap is $\sim 210\text{ KB}$. Exceeding 64 KB risks memory fragmentation during Wi-Fi socket allocation.
3. **Flash Footprint Limit:** $\le 750\text{ KB}$.
   - *Rationale:* With the default 4MB SPI flash partition (`default.csv` with 1.2MB app partition, or `huge_app.csv` with 3MB app partition), keeping model weights under 750 KB leaves ample space for ESP32 Wi-Fi and FreeRTOS libraries.

---

## 6. Adapter C++ Interface (Header Contract)

The teammate's implementation will conform to the following clean C++ adapter interface (`model_adapter.h`):

```cpp
#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Structure returned to firmware after inference step
typedef struct {
    float prob_normal;      // Probability [0.0 - 1.0] of normal laminar operation
    float prob_leak;        // Probability [0.0 - 1.0] of turbulent leak
    float prob_noise;       // Probability [0.0 - 1.0] of workshop background noise
    float anomaly_score;    // Out-of-distribution score (0.0 if unsupported)
    uint16_t latency_ms;    // Measured execution time in milliseconds
    bool is_valid;          // True if inference executed successfully
    char top_label[16];     // Primary winning label string
} TinyMLResult;

// Model Adapter Lifecycle Functions
bool tinyml_is_available(void);
bool tinyml_init(void);
bool tinyml_infer(const float* sample_window, uint32_t num_samples, TinyMLResult* result);

#ifdef __cplusplus
}
#endif
```

---

## 7. Fallback Logic When Model is Absent or Fails

When `tinyml_is_available()` returns `false` or `tinyml_infer()` returns `false`:

1. The firmware automatically falls back to:
   $$R_{\text{RMS}} = \frac{\text{RMS}_{\text{window}}}{\text{RMS}_{\text{baseline}}}$$
2. If $R_{\text{RMS}} \ge 3.0$ (`FALLBACK_LEAK_RATIO`) for 2 consecutive windows, `ROLE_LEAK` is asserted.
3. The OLED displays `LEAK(RMS)` or `NORMAL(RMS)` to transparently inform the operator that the prediction is rule-based and not derived from an ML model.
4. The telemetry field `lbl` in the JSON payload sent to `POST /api/log` records `"leak(rms)"` or `"no_leak(rms)"`, preserving complete provenance.
