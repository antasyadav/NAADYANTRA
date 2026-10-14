# HazGuard TinyML Current State Documentation

**Date:** 2026-10-13
**Document Version:** 1.0
**Purpose:** Document existing infrastructure, verified configuration, and missing components for TinyML leak detection integration.

---

## 1. Verified Firmware Configuration

### File: `leak_detector.ino`
**Lines:** 1,187
**Platform:** ESP32-S3 / ESP32 DevKit (Dual-Core 240MHz Xtensa)
**Firmware Version:** 1.1.0

### Verified Sampling and Signal Processing Parameters

| Parameter | Value | Location | Notes |
|-----------|-------|----------|-------|
| Sampling Rate | 4000 Hz | Line 105 | `SAMPLE_RATE_HZ` - Confirmed |
| Window Duration | 1000 ms | Line 106 | `WINDOW_MS` - Confirmed |
| Hop Duration | 500 ms | Line 107 | `HOP_MS` - Confirmed (50% overlap) |
| ADC Resolution | 12-bit | Line 324 | `analogReadResolution(12)` |
| ADC Attenuation | 11 dB | Line 340 | `ADC_11db` |
| Nyquist Frequency | 2000 Hz | Calculated | 4000 Hz / 2 |
| DC-Block Filter Coefficient | 0.995 | Line 108 | `DC_BLOCK_R` - First-order IIR |
| Minimum Signal RMS | 0.8 ADC counts | Line 114 | `MIN_SIGNAL_RMS` |
| Fallback Leak Ratio | 3.0 | Line 116 | `FALLBACK_LEAK_RATIO` (RMS-to-baseline) |

### Confirmed Sensor Hardware Configuration

| Sensor | Pin (ESP32-S3) | ADC Channel | Status |
|--------|----------------|-------------|--------|
| Piezo (Main) | GPIO 4 | ADC1 | Active |
| Reference Mic | GPIO 7 | ADC1 | Disabled (`USE_REFERENCE_SENSOR = 0`) |
| Gas Sensor (MQ) | GPIO 5 | ADC1 | Active (`HAS_GAS_SENSOR = 1`) |
| Moisture Probe | GPIO 6 | ADC1 | Active (`HAS_MOISTURE_SENSOR = 1`) |
| UV Sensor | GPIO 1 | ADC1 | Disabled (`HAS_UV_SENSOR = 0`) |
| Heat Sensor (MLX90614) | I2C (SDA=8, SCL=9) | I2C | Disabled (`HAS_HEAT_SENSOR = 0`) |

### Firmware Modes

**Line 50:** `RUN_MODE` is set to `RUN_MODE_DETECT` (value 0)
- **RUN_MODE_COLLECT (1):** Available for dataset acquisition, streams filtered samples over Serial at 921600 baud
- **RUN_MODE_DETECT (0):** Current mode, performs leak detection with either Edge Impulse or RMS fallback

### Edge Impulse Integration Status

**Line 52:** `USE_EDGE_IMPULSE = 1` (enabled)
**Line 167:** Placeholder include `#include <YOUR_PROJECT_inferencing.h>` - **MISSING**
**Line 168:** Static assert expecting `EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME == 1`

**Current Status:** Firmware will **FAIL TO COMPILE** until:
1. Edge Impulse model header file is generated and placed in project directory
2. Include path is corrected to actual filename
3. Model parameters match firmware expectations (4000 Hz, single-axis input)

### Signal Processing Pipeline (Verified)

1. **ADC Acquisition:** 12-bit raw samples (0-4095) at 4000 Hz
2. **DC-Block Filter:** First-order IIR filter with coefficient 0.995 removes ~1.65V virtual ground offset
3. **Ring Buffer:** Power-of-two circular buffer (size calculated from window length)
4. **Window Extraction:** 4000 samples per window (1000 ms at 4000 Hz)
5. **RMS Calculation:** RMS energy computed per window
6. **Classification:**
   - **TinyML Path (intended):** Edge Impulse inference on windowed samples
   - **Fallback Path:** RMS-to-baseline ratio with threshold 3.0

### Alert and Detection Logic

**Leak Detection Thresholds:**
- `LEAK_PROB_MIN = 0.65` (65% confidence minimum)
- `LEAK_CONFIRM_WINDOWS = 2` (consecutive positive windows required)
- `LEAK_CLEAR_WINDOWS = 4` (consecutive negative windows to clear)

**Debounce Logic:** Implemented in `Debounce` struct (lines 202-210)

### Telemetry and Backend Integration

**Logging Endpoint:** `POST /api/log` (lines 695-708)
**Headers:**
- `Content-Type: application/json`
- `X-Device-Key: DEVICE_KEY` (currently hardcoded to `"dev-key-123"`)

**Payload Fields (Event):**
```json
{
  "t": epoch_timestamp,
  "up": device_uptime_ms,
  "ev": event_name,
  "alert": "OK|CAUTION|DANGER",
  "cause": "LEAK|GAS_ALARM|WET|...",
  "lbl": model_label,
  "pl": leak_probability,
  "rms": rms_value,
  "gas": gas_delta,
  "gr": gas_ratio,
  "tc": temperature_celsius,
  "uv": uv_delta,
  "wet": wet_boolean
}
```

**TLS Status:** Line 716 - `secure.setInsecure()` - **INSECURE CONFIGURATION**
- TLS verification disabled for local bench testing
- Must be fixed before production deployment

---

## 2. Verified Backend Configuration

### Backend: FastAPI Application
**Location:** `backend/` directory
**Framework:** FastAPI 0.115.0
**Database:** SQLite (default: `hazguard.db`)
**ORM:** SQLAlchemy 2.0.35

### Ingestion Endpoint

**File:** `backend/routers/ingestion.py`
**Endpoint:** `POST /api/log`
**Authentication:** Device key via `X-Device-Key` header
**Idempotency:** SHA-256-based idempotency key for duplicate prevention

**Accepted Payload Kinds:**
- `event`: Individual event records
- `summary`: Session summary records

**Auto-Registration:** Devices auto-register on first valid request if not in database

### Database Schema (Verified in `backend/schemas.py`)

**Event Model Fields (lines 115-141):**
- `model_label`: TinyML prediction label (optional)
- `leak_probability`: Float confidence score (optional)
- `rms`: Signal RMS (optional)
- `gas_delta`, `gas_ratio`: Gas sensor readings (optional)
- `temperature`, `uv_delta`, `wet`: Environmental readings (optional)
- `firmware_version`: Firmware version string (optional)

**Status:** Backend schema **ALREADY SUPPORTS** TinyML predictions
- No schema changes required for basic ML integration
- Optional extension fields (model version, inference status) can be added later

### Security Issues

**File:** `leak_detector.ino` line 67
**Issue:** Hardcoded device key `"dev-key-123"`
**File:** `leak_detector.ino` line 716
**Issue:** TLS verification disabled (`secure.setInsecure()`)

**File:** `.env` (not committed to Git, expected)
**Backend Config:** `backend/config.py` lines 10-13
- Uses `secret_key` from environment
- Uses `device_key_hash` from environment
- These should be properly configured for production

---

## 3. Flutter Application Status

**Location:** `mobile_app/` directory
**Framework:** Flutter
**State Management:** Riverpod
**Routing:** GoRouter
**Networking:** Dio
**Local Storage:** SQLite

**Status:** Existing telemetry models already distinguish between:
- Rule-based detections
- Sensor readings
- Device offline status

**Required Changes:**
- Add ML prediction fields to telemetry display
- Distinguish between rule-based and ML-based leak detections
- Display model confidence scores appropriately
- Handle model unavailable/inference error states

**Visual Identity:** HazGuard design system confirmed (ivory/off-white, carbon/graphite, burnt-orange)

---

## 4. Missing ML Infrastructure

### Dataset Status

**Search Result:** **NO DATASETS FOUND**
- No existing recordings in workspace
- No data directories found
- No synthetic data generators found
- No public dataset downloads

**Required:**
- Complete dataset acquisition pipeline
- Data manifest system
- Data inspection and validation tools

### Training Pipeline Status

**Search Result:** **NO TRAINING INFRASTRUCTURE FOUND**
- No `ml/` directory
- No training scripts
- No feature extraction code
- No model files
- No evaluation scripts

**Required:**
- Complete training pipeline from scratch
- Signal preprocessing matching firmware
- Feature extraction (RMS, spectral features, etc.)
- Model training code
- Evaluation and validation framework

### Model Export Status

**Search Result:** **NO MODEL FILES FOUND**
- No TFLite models
- No ONNX models
- No Edge Impulse projects
- No model headers

**Required:**
- Model training to generate artifact
- Export to embedded-compatible format
- Model integration testing

### Serial Collection Tool Status

**Search Result:** **NO COLLECTION TOOL FOUND**
- No Python serial capture scripts
- No collection utilities
- No labeling interface

**Required:**
- Serial data capture utility for `RUN_MODE_COLLECT` mode
- Labeling interface
- Metadata recording

---

## 5. Hardware Constraints

### ESP32-S3 Resources

**ADC Resolution:** 12-bit (0-4095)
**RAM:** Need to verify PSRAM availability
**Flash:** Need to verify flash size
**Clock:** 240 MHz dual-core

**Sampling Constraints:**
- Nyquist frequency: 2000 Hz
- Cannot detect > 2000 Hz content (ultrasonic 28-39 kHz not reachable at 4000 Hz sampling)
- Any ultrasonic content will be aliased

**Memory Constraints:**
- Ring buffer size: ~8 KB (power-of-two allocation for 4000 samples)
- Feature buffer: ~16 KB (4000 floats)
- Model memory: TBD based on selected architecture

---

## 6. Summary of Verified Facts

### What Exists and Works

1. **Firmware Signal Pipeline:**
   - 4000 Hz sampling confirmed
   - 1000 ms window, 500 ms hop confirmed
   - DC-block IIR filter implemented
   - RMS calculation implemented
   - Ring buffer management implemented
   - `RUN_MODE_COLLECT` mode functional for data capture

2. **Backend API:**
   - `POST /api/log` endpoint functional
   - Device authentication implemented
   - Idempotency implemented
   - Schema supports ML predictions
   - Auto-registration implemented

3. **Flutter App:**
   - Telemetry display infrastructure exists
   - Offline caching implemented
   - Design system defined

### What is Missing

1. **Dataset:**
   - No real recordings
   - No public datasets acquired
   - No synthetic data generator

2. **Training Pipeline:**
   - No `ml/` directory structure
   - No preprocessing code
   - No feature extraction code
   - No training scripts
   - No evaluation code

3. **Model:**
   - No trained model
   - No exported model
   - No Edge Impulse integration
   - Firmware missing model header file

4. **Collection Tool:**
   - No serial capture utility
   - No labeling interface

5. **Security:**
   - Hardcoded device key in firmware
   - TLS verification disabled

---

## 7. Immediate Blocking Issues

1. **Firmware Will Not Compile:**
   - Missing `YOUR_PROJECT_inferencing.h` file
   - Line 167 includes non-existent file

2. **No Training Data:**
   - Cannot train model without data
   - Must create synthetic data or acquire public datasets

3. **No Training Infrastructure:**
   - Must build entire pipeline from scratch

---

## 8. Next Steps

1. Create `ml/` directory structure
2. Create synthetic data generator for preliminary pipeline
3. Research and document public acoustic leak detection datasets
4. Build signal preprocessing pipeline matching firmware
5. Train baseline model on synthetic data
6. Export model and integrate into firmware
7. Create serial collection tool for real data acquisition
8. Fix security issues (device key, TLS)

---

**Document Status:** Complete - Based on actual code inspection
**Verification:** All values verified against source code lines referenced
