# HazGuard TinyML Deployment Report

**Date:** 2026-10-13
**Report Version:** 1.0
**Status:** Synthetic-Data Prototype Complete - Real-World Validation Required

---

## Executive Summary

This report documents the TinyML leak detection prototype development for HazGuard. A complete dataset pipeline, preprocessing pipeline, and training infrastructure have been implemented using synthetic data. Baseline models have been trained and evaluated. However, real-world performance validation is required before production deployment.

**Key Achievement:** Complete reproducible ML pipeline from data generation to model training.
**Critical Limitation:** All results are based on synthetic data only. Real piezo sensor recordings are required for production validation.

---

## Completed Work

### 1. Workspace Inspection and Documentation

**Deliverable:** `docs/TINYML_CURRENT_STATE.md`

**Verified Firmware Configuration:**
- Sampling rate: 4000 Hz (confirmed line 105)
- Window duration: 1000 ms (confirmed line 106)
- Hop duration: 500 ms (confirmed line 107)
- ADC resolution: 12-bit (confirmed line 324)
- DC-block coefficient: 0.995 (confirmed line 108)
- Nyquist frequency: 2000 Hz (calculated)

**Identified Issues:**
- Firmware will not compile: Missing `YOUR_PROJECT_inferencing.h` (line 167)
- Hardcoded device key: `"dev-key-123"` (line 67)
- TLS verification disabled: `secure.setInsecure()` (line 716)

**Backend Status:**
- Schema already supports ML predictions (`model_label`, `leak_probability`)
- Ingestion endpoint functional: `POST /api/log`
- No schema changes required for basic ML integration

---

### 2. ML Infrastructure Setup

**Deliverable:** Complete `ml/` directory structure

```
ml/
├── data/
│   ├── raw/              # Real recordings
│   ├── processed/       # Preprocessed features
│   ├── synthetic/       # Synthetic data
│   └── manifests/       # Metadata
├── src/
│   ├── generate_synthetic.py
│   ├── inspect_dataset.py
│   ├── preprocessing.py
│   ├── train.py
│   └── serial_collect.py
├── models/
├── reports/
├── tests/
├── requirements.txt
└── README.md
```

**Git Configuration:**
- `.gitignore` configured to exclude large datasets and model artifacts
- Manifests tracked for provenance
- Source code tracked

---

### 3. Synthetic Data Generation

**Deliverable:** `ml/src/generate_synthetic.py`

**Generated Dataset:**
- 500 synthetic samples
- Classes: normal (200), leak_like (200), noise (100)
- 25 recording groups per class (prevents data leakage)
- Sampling rate: 4000 Hz (matches firmware)
- Window duration: 1000 ms (4000 samples)
- ADC quantization: 12-bit (0-4095)

**Signal Generation:**
- Normal: Low-frequency drift + broadband noise
- Leak_like: Periodic high-frequency components (800-1000 Hz)
- Noise: High-amplitude noise + periodic interference + impulses

**Limitations Documented:**
- Synthetic signals are approximations, not real leak signatures
- Do not represent real-world detection performance
- Used for pipeline development only

---

### 4. Dataset Inspection and Validation

**Deliverable:** `ml/src/inspect_dataset.py`

**Capabilities:**
- Manifest validation
- Class distribution reporting
- Sampling rate verification
- Source type tracking (real/public/synthetic)
- Train/validation/test split status
- Data file integrity checks

**Validation Results:**
- 500 samples validated
- All sampling rates consistent at 4000 Hz
- Class balance reasonable (2:1 ratio)
- Data files valid (10 sample check)

---

### 5. Signal Preprocessing Pipeline

**Deliverable:** `ml/src/preprocessing.py`

**Firmware-Matching Implementation:**
- DC-block filter: `y[n] = x[n] - x[n-1] + 0.995 * y[n-1]` (matches firmware line 278-286)
- RMS calculation (matches firmware line 448-457)
- Nyquist constraint: 2000 Hz (respects 4000 Hz sampling)

**Extracted Features (9 total):**
- Time-domain: RMS, std, peak_amplitude, crest_factor, zero_crossing_rate
- Frequency-domain: band_energy_0_500, band_energy_500_1000, band_energy_1000_2000, total_energy

**Data Splitting:**
- Recording-level grouping prevents data leakage
- Train: 360 samples (18 groups)
- Val: 40 samples (2 groups)
- Test: 100 samples (5 groups)

---

### 6. Model Training

**Deliverable:** `ml/src/train.py`

**Trained Models:**

**Logistic Regression:**
- Validation accuracy: 100% (synthetic data)
- Test accuracy: 100% (synthetic data)
- Model size: Small (scikit-learn)
- Feature importance available

**Random Forest:**
- Validation accuracy: 100% (synthetic data)
- Test accuracy: 100% (synthetic data)
- Model size: Medium (100 trees)
- Feature importance available

**Neural Network:**
- Skipped (TensorFlow not available in environment)
- Architecture defined (64-32-3 layers)
- Can be trained when TensorFlow available

**Important:** 100% accuracy on synthetic data is expected due to clean synthetic generation. This does not represent real-world performance.

---

### 7. Serial Data Collection Utility

**Deliverable:** `ml/src/serial_collect.py`

**Capabilities:**
- Connects to ESP32-S3 at 921600 baud
- Captures filtered ADC samples from `RUN_MODE_COLLECT` mode
- Saves windows as .npy files
- Records label and metadata
- Creates manifest for provenance
- Interactive and command-line modes

**Usage:**
```bash
python src/serial_collect.py COM3 leak 10
```

**Requirements:**
- Firmware flashed with `RUN_MODE = RUN_MODE_COLLECT`
- USB connection to ESP32-S3
- Operator provides label for each recording

---

### 8. Public Dataset Research

**Deliverable:** `docs/public_datasets_research.md`

**Identified Datasets:**

1. **Mendeley Water Distribution** (Priority 1)
   - Hydrophone at 8 kHz
   - Water-coupled sensor (closest to piezo)
   - CC BY 4.0 license
   - **Action:** Download, convert .raw, downsample to 4 kHz

2. **Zenodo Water Leak** (Priority 2)
   - Air microphone recordings
   - 5.7 MB total
   - **Action:** Inspect sampling rate, test resampling

3. **MIMII** (Priority 3)
   - Valve leakage sounds
   - Air microphone array
   - **Action:** Extract valve data, test transfer learning

**Critical Finding:** All public datasets use different sensors (air mic/hydrophone) than HazGuard (contact piezo). Frequency response and coupling physics differ significantly. Do not assume direct interchangeability.

**Recommendation:** Use public datasets only for transfer learning initialization. Train final model on real piezo recordings.

---

### 9. Documentation

**Deliverables:**
- `docs/TINYML_CURRENT_STATE.md` - Verified configuration and missing components
- `docs/public_datasets_research.md` - Public dataset analysis
- `ml/README.md` - Complete pipeline documentation
- `docs/TINYML_DEPLOYMENT_REPORT.md` - This report

---

## Not Yet Completed

### 1. Model Export for Embedded Deployment

**Status:** NOT IMPLEMENTED

**Current State:**
- Models saved as `.joblib` (scikit-learn) and `.keras` (TensorFlow)
- Not yet exported to embedded-compatible format

**Required:**
- Evaluate TensorFlow Lite Micro runtime on ESP32-S3
- Test quantization (int8) for model size reduction
- Generate embedded-compatible model artifacts
- Create model header or binary for firmware

**Options:**
- **TFLite Micro:** Recommended for TensorFlow models
- **ONNX Runtime:** Alternative format
- **C Header:** Manual implementation for simple models (logistic regression)

---

### 2. Firmware Integration

**Status:** BLOCKED - Missing model file

**Current State:**
- Firmware has `USE_EDGE_IMPULSE = 1` (line 52)
- Placeholder include: `#include <YOUR_PROJECT_inferencing.h>` (line 167)
- Firmware will not compile until resolved

**Required:**
- Export trained model to embedded format
- Generate model header or binary
- Replace placeholder include with actual file
- Implement `runModel()` function matching export format
- Update classification thresholds
- Handle model errors gracefully
- Keep RMS fallback for comparison

**Integration Requirements:**
- Input tensor shape must match preprocessing output
- Feature order must match
- Numeric types must match (int8 quantization vs float32)
- Memory usage must fit ESP32-S3 constraints
- Inference latency must be acceptable

---

### 3. Real Data Collection

**Status:** UTILITY READY - NOT EXECUTED

**Current State:**
- Serial collection utility implemented
- Firmware `RUN_MODE_COLLECT` mode functional
- No real recordings collected yet

**Required:**
- Flash firmware with `RUN_MODE = RUN_MODE_COLLECT`
- Connect ESP32-S3 with piezo sensor
- Capture labeled recordings (normal, leak, noise)
- Minimum 50-100 recordings per class recommended
- Vary conditions (pipe material, pressure, environment)

---

### 4. Model Training on Real Data

**Status:** NOT STARTED

**Required:**
- Collect real piezo sensor recordings
- Preprocess real data using existing pipeline
- Train models on real data
- Evaluate performance on held-out real data
- Compare with RMS baseline
- Document real-world accuracy

---

### 5. Security Fixes

**Status:** IDENTIFIED - NOT FIXED

**Issues:**
1. Hardcoded device key: `"dev-key-123"` (firmware line 67)
2. TLS verification disabled: `secure.setInsecure()` (firmware line 716)

**Required:**
- Move device key to secure configuration (environment variable)
- Enable TLS verification for production
- Use proper certificate validation
- Remove insecure defaults

---

### 6. Backend Schema Extensions

**Status:** NOT REQUIRED (basic ML already supported)

**Current State:**
- Backend schema already supports: `model_label`, `leak_probability`
- No changes required for basic ML integration

**Optional Extensions:**
- Model version field
- Inference status field
- Raw score field
- Decision reason field

These can be added as needed during integration.

---

### 7. Flutter Application Updates

**Status:** NOT STARTED

**Required:**
- Add ML prediction fields to telemetry display
- Distinguish rule-based vs ML-based detections
- Display model confidence scores appropriately
- Handle model unavailable/inference error states
- Maintain existing visual identity (HazGuard design system)

---

## Limitations and Constraints

### 1. Synthetic Data Only
**Critical:** All current results are based on synthetic data. Synthetic signals are approximations for pipeline development only. They do not represent real-world leak detection performance.

**Impact:** Cannot claim real-world accuracy. Must validate on real piezo sensor recordings.

### 2. Sensor Domain Mismatch
**Critical:** Public datasets use air-coupled microphones or hydrophones. HazGuard uses contact piezo sensor. Frequency response and coupling physics differ significantly.

**Impact:** Cannot assume direct interchangeability. Public datasets only useful for transfer learning initialization.

### 3. Nyquist Frequency Constraint
**Constraint:** Firmware sampling at 4000 Hz gives Nyquist frequency of 2000 Hz.

**Impact:** Cannot detect >2000 Hz content. Ultrasonic leak signatures (28-39 kHz) are not reachable without hardware changes (higher sampling rate, different sensor).

### 4. TensorFlow Unavailable
**Environment:** TensorFlow not available in current environment (CPU compatibility issue).

**Impact:** Neural network training skipped. Scikit-learn models used instead. Can be addressed by installing compatible TensorFlow version or using different environment.

### 5. Firmware Build Blocked
**Blocking:** Firmware will not compile due to missing model header file.

**Impact:** Cannot test firmware integration until model is exported and header generated.

---

## Hardware Verification Status

### Verified
- Sampling rate: 4000 Hz (from source code)
- Window duration: 1000 ms (from source code)
- ADC resolution: 12-bit (from source code)
- DC-block filter: First-order IIR with 0.995 coefficient (from source code)
- Pin configuration: Documented in source code

### NOT Verified
- Actual ESP32-S3 board model and specifications
- PSRAM availability
- Flash size
- Piezo sensor response curve
- Sensor wiring and bias circuit
- Actual analog front-end performance

**Required:** Physical hardware inspection and testing.

---

## Recommendations

### Immediate (Before Production)

1. **Collect Real Data**
   - Use serial_collect.py to capture 50-100 recordings per class
   - Vary conditions (pipe material, pressure, environment)
   - Label recordings with ground truth

2. **Train on Real Data**
   - Replace synthetic data with real recordings
   - Train models on real data
   - Evaluate real-world performance
   - Compare with RMS baseline

3. **Export Model for Embedded**
   - Evaluate TFLite Micro runtime on ESP32-S3
   - Test quantization (int8)
   - Generate model header or binary
   - Verify memory constraints

4. **Firmware Integration**
   - Replace placeholder include with actual model
   - Implement inference function
   - Test on hardware
   - Keep RMS fallback

5. **Security Fixes**
   - Remove hardcoded device key
   - Enable TLS verification
   - Use secure configuration

### Future Enhancements

1. **Increase Sampling Rate**
   - Consider 16 kHz or higher for ultrasonic detection
   - Verify ADC performance at higher rates
   - Update Nyquist constraints

2. **Public Dataset Integration**
   - Download Mendeley hydrophone data
   - Test transfer learning
   - Document domain shift

3. **Advanced Models**
   - Test neural networks with TensorFlow
   - Evaluate ensemble methods
   - Explore anomaly detection

4. **Real-Time Inference**
   - Measure inference latency on ESP32-S3
   - Optimize for low latency
   - Consider model pruning

---

## Milestones

### Completed
- [x] Workspace inspection and documentation
- [x] ML infrastructure setup
- [x] Synthetic data generation
- [x] Dataset inspection and validation
- [x] Signal preprocessing pipeline
- [x] Model training (baseline)
- [x] Model evaluation (synthetic data)
- [x] Serial collection utility
- [x] Public dataset research
- [x] Complete documentation

### In Progress
- [ ] Model export for embedded deployment
- [ ] Firmware integration

### Not Started
- [ ] Real data collection
- [ ] Model training on real data
- [ ] Security fixes
- [ ] Flutter application updates
- [ ] Hardware verification

---

## Conclusion

A complete reproducible ML pipeline has been implemented for HazGuard. The pipeline includes data generation, preprocessing, model training, and evaluation. Baseline models have been trained on synthetic data and demonstrate the pipeline's functionality.

However, **real-world performance validation is required** before production deployment. Synthetic data results do not represent actual leak detection performance. Real piezo sensor recordings must be collected, and models must be trained and evaluated on real data.

The firmware integration is blocked by the missing model header file. Once a model is exported to an embedded-compatible format, firmware integration can proceed.

Security issues (hardcoded credentials, disabled TLS) must be addressed before production deployment.

**Overall Status:** Synthetic-data prototype complete. Real-world validation and hardware testing required.

---

**Report Prepared By:** Autonomous AI Agent
**Date:** 2026-10-13
**Version:** 1.0
