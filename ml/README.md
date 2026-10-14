# HazGuard TinyML Pipeline

Acoustic leak detection training and deployment pipeline for ESP32-S3 firmware.

**IMPORTANT:** This pipeline currently uses synthetic data for development. Synthetic data is for pipeline prototyping only and does not represent real-world leak detection performance. Real piezo sensor recordings must be collected using the serial collection utility before production deployment.

---

## Directory Structure

```
ml/
├── data/
│   ├── raw/              # Real recordings from ESP32-S3 (git-ignored)
│   ├── processed/       # Preprocessed features (git-ignored)
│   ├── synthetic/       # Synthetic generated data (git-ignored)
│   └── manifests/       # Dataset metadata and provenance (tracked)
├── src/
│   ├── generate_synthetic.py    # Synthetic data generator
│   ├── inspect_dataset.py       # Dataset inspection and validation
│   ├── preprocessing.py         # Signal preprocessing pipeline
│   ├── train.py                 # Model training
│   └── serial_collect.py        # Serial data collection utility
├── models/               # Trained models (git-ignored)
├── reports/              # Training reports (git-ignored)
├── tests/                # Pipeline tests
├── requirements.txt      # Python dependencies
└── README.md            # This file
```

---

## Installation

### Prerequisites
- Python 3.8+
- pip

### Install Dependencies
```bash
cd ml
pip install -r requirements.txt
```

**Note:** TensorFlow is optional. If installation fails due to CPU compatibility, the pipeline will skip neural network training and use scikit-learn models only.

---

## Quick Start

### 1. Generate Synthetic Data (for pipeline development)
```bash
cd ml
python src/generate_synthetic.py
```

This generates 500 synthetic samples (200 normal, 200 leak_like, 100 noise) in `data/synthetic/`.

### 2. Inspect Dataset
```bash
python src/inspect_dataset.py data/synthetic
```

### 3. Preprocess and Extract Features
```bash
python src/preprocessing.py
```

This:
- Applies DC-block filter matching firmware
- Extracts time-domain features (RMS, std, peak, crest factor, ZCR)
- Extracts frequency-domain band energies (0-500 Hz, 500-1000 Hz, 1000-2000 Hz)
- Splits data by recording group to prevent leakage
- Saves features to `data/synthetic/features_*.csv`

### 4. Train Models
```bash
python src/train.py
```

This trains:
- Logistic Regression baseline
- Random Forest baseline
- Neural Network (if TensorFlow available)

Models are saved to `models/` with metadata.

### 5. Collect Real Data (for production)
```bash
# Flash firmware with RUN_MODE = 1
# Connect ESP32-S3 via USB
python src/serial_collect.py
```

Interactive mode guides you through capturing labeled recordings.

---

## Firmware Compatibility

### Verified Parameters (from `leak_detector.ino`)

| Parameter | Value | Location |
|-----------|-------|----------|
| Sampling Rate | 4000 Hz | Line 105 |
| Window Duration | 1000 ms | Line 106 |
| Hop Duration | 500 ms | Line 107 |
| ADC Resolution | 12-bit | Line 324 |
| DC-Block Coefficient | 0.995 | Line 108 |
| Nyquist Frequency | 2000 Hz | Calculated |

### Signal Processing Pipeline

The preprocessing pipeline exactly matches the firmware:

1. **ADC Acquisition:** 12-bit samples (0-4095) at 4000 Hz
2. **DC-Block Filter:** First-order IIR: `y[n] = x[n] - x[n-1] + 0.995 * y[n-1]`
3. **Window Extraction:** 4000 samples per window (1000 ms)
4. **Feature Extraction:** RMS, std, peak, crest factor, ZCR, band energies

**Constraint:** Firmware Nyquist frequency is 2000 Hz. The pipeline does not attempt to detect >2000 Hz content.

---

## Dataset Sources

### Current Status
- **Synthetic Data:** 500 samples generated for pipeline development
- **Public Datasets:** Research documented in `docs/public_datasets_research.md`
- **Real Recordings:** Not yet collected (use serial_collect.py)

### Public Dataset Research

Identified datasets with domain limitations:
1. **Mendeley Water Distribution** (Priority 1): Hydrophone at 8 kHz, closest to piezo
2. **Zenodo Water Leak** (Priority 2): Air microphone, 5.7 MB
3. **MIMII** (Priority 3): Valve leakage sounds, air microphone

**Critical:** All public datasets use different sensors (air mic/hydrophone) than HazGuard (contact piezo). Frequency response and coupling physics differ. Do not assume direct interchangeability.

**Recommendation:** Use public datasets only for transfer learning initialization. Train final model on real piezo recordings.

---

## Model Training

### Supported Models
- Logistic Regression (scikit-learn)
- Random Forest (scikit-learn)
- Neural Network (TensorFlow, optional)

### Features
- Time-domain: RMS, std, peak_amplitude, crest_factor, zero_crossing_rate
- Frequency-domain: band_energy_0_500, band_energy_500_1000, band_energy_1000_2000, total_energy

### Data Splitting
Recording-level grouping prevents data leakage. Samples from the same recording are not distributed across train/val/test splits.

### Evaluation Metrics
- Accuracy
- Precision, Recall, F1-score per class
- Confusion matrix
- Model size

---

## Serial Data Collection

### Firmware Configuration
Set `RUN_MODE = RUN_MODE_COLLECT` (value 1) in `leak_detector.ino`:
```cpp
#define RUN_MODE  RUN_MODE_COLLECT
```

Flash firmware to ESP32-S3.

### Collection Utility
```bash
# Interactive mode
python src/serial_collect.py

# Command line mode
python src/serial_collect.py COM3 leak 10
```

The utility:
- Connects to ESP32-S3 at 921600 baud
- Captures filtered ADC samples
- Saves windows as .npy files
- Records label and metadata
- Creates manifest for provenance

### Labels
Recommended labels:
- `normal`: Normal operating conditions
- `leak`: Confirmed leak (ground truth)
- `noise`: High-noise environments

---

## Model Export

Current status: **NOT YET IMPLEMENTED**

Models are saved as:
- Scikit-learn: `.joblib` files
- TensorFlow: `.keras` files

For ESP32-S3 deployment, export to:
- **TFLite Micro**: Recommended for TensorFlow models
- **ONNX**: Alternative format
- **C Header**: Manual implementation for simple models

Next steps:
1. Evaluate TensorFlow Lite Micro runtime on ESP32-S3
2. Test quantization (int8) for model size reduction
3. Generate embedded-compatible model artifacts
4. Integrate with firmware inference function

---

## Firmware Integration

### Current Status
Firmware has placeholder Edge Impulse integration (`USE_EDGE_IMPULSE = 1`) but missing model header file (`YOUR_PROJECT_inferencing.h`). Firmware will not compile until resolved.

### Integration Plan
1. Export trained model to embedded-compatible format
2. Generate model header or binary
3. Implement `runModel()` function in firmware
4. Match input tensor shape to preprocessing output
5. Handle model errors gracefully
6. Keep RMS fallback for comparison

### Required Changes in `leak_detector.ino`
- Replace placeholder include with actual model header
- Implement inference function matching Edge Impulse or custom runtime
- Update classification thresholds
- Handle model unavailable states

---

## Security Notes

### Issues Identified
1. **Hardcoded device key:** `"dev-key-123"` in firmware (line 67)
2. **TLS disabled:** `secure.setInsecure()` in firmware (line 716)

### Required Fixes
- Move device key to secure configuration
- Enable TLS verification for production
- Use proper certificate validation

---

## Testing

Run pipeline tests:
```bash
cd ml
python -m pytest tests/
```

Test coverage:
- Dataset parsing and manifest validation
- Signal preprocessing and feature extraction
- Data split integrity
- Model training and evaluation
- Serial capture protocol

---

## Important Notes

### Synthetic Data Limitations
Synthetic signals are **APPROXIMATIONS** for pipeline development only. They are NOT validated real-world leak signatures. Do not use synthetic-only results as evidence of real-world performance.

### Sensor Domain Mismatch
Public datasets use air-coupled microphones or hydrophones. HazGuard uses contact piezo sensor. Frequency response and coupling physics differ significantly.

### Nyquist Constraint
Firmware sampling at 4000 Hz gives Nyquist frequency of 2000 Hz. Cannot detect >2000 Hz content. Ultrasonic leak signatures (28-39 kHz) are not reachable without hardware changes.

### Real-World Validation Required
This pipeline is a prototype. Real-world leak detection performance must be validated on:
- Actual piezo sensor recordings
- Real pipe materials and pressures
- Real environmental conditions
- Actual ESP32-S3 hardware

---

## Next Steps

1. **Collect Real Data:** Use serial_collect.py to capture labeled recordings
2. **Train on Real Data:** Replace synthetic data with real recordings
3. **Export Model:** Convert to TFLite Micro or similar embedded format
4. **Firmware Integration:** Implement inference function in leak_detector.ino
5. **Hardware Testing:** Test on actual ESP32-S3 with real sensors
6. **Security Fixes:** Remove hardcoded credentials, enable TLS

---

## References

- Firmware: `leak_detector.ino`
- Backend: `backend/` (FastAPI, SQLAlchemy)
- Flutter App: `mobile_app/` (Flutter, Riverpod)
- Current State: `docs/TINYML_CURRENT_STATE.md`
- Public Datasets: `docs/public_datasets_research.md`

---

**Status:** Synthetic-data prototype complete. Real-world validation required.
