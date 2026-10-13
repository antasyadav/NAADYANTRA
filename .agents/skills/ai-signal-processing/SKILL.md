---
name: ai-signal-processing
description: >-
  Acoustic and time-series signal processing with Python, FastAPI, NumPy/SciPy,
  FFT, spectrogram extraction, ONNX model serving, and leak frequency detection.
---

# Acoustic Signal Processing & AI Skill

## Signal Processing Best Practices
1. **FFT & Frequency Domain Analysis**:
   - Sample rate validation (e.g. 16kHz / 44.1kHz) against hardware ADC capabilities.
   - Compute Fast Fourier Transform (FFT) and Power Spectral Density (PSD) to locate dominant frequency bands characteristic of pressurized valve leakages (typically 20kHz - 40kHz ultrasound downconverted, or 1kHz - 8kHz audible spectrum).
2. **Feature Extraction Pipeline**:
   - Extract spectral centroid, spectral bandwidth, zero-crossing rate, and Mel-Frequency Cepstral Coefficients (MFCCs).
3. **Inference with ONNX**:
   - Export PyTorch models to ONNX for CPU-efficient inference without heavyweight GPU dependencies.
   - Test preprocessing pipelines on reproducible synthetic acoustic fixtures.
