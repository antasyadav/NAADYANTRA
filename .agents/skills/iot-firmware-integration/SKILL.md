---
name: iot-firmware-integration
description: >-
  IoT firmware integration specialist for ESP32 and ESP32-S3 C++ code, acoustic sensor
  sampling, hardware telemetry verification, serial protocols, and zero fabrication.
---

# IoT & ESP32 Firmware Integration Skill

## Engineering Directives
1. **Hardware Protocol Fidelity**:
   - Strictly follow documented pinouts, I2C/SPI buses, and serial baud rates defined in `leak_detector.ino`.
   - Never fabricate non-existent hardware sensors, BLE services, or communication packets.
2. **Firmware-to-Backend Alignment**:
   - Ensure JSON or binary payloads emitted by ESP32 match the ingestion schemas defined in `backend/routers/ingestion.py`.
   - Validate calibration offsets and unit definitions (dB, Hz, PSI, Celsius) across firmware, backend, and mobile UI.
3. **Robust Connection Lifecycle**:
   - Handle Wi-Fi and BLE reconnect loops with exponential backoff on the microcontroller.
   - Buffer sensor samples locally in flash memory or ring buffers during transient network drops.
