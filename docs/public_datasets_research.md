# Public Acoustic Leak Detection Datasets

**Document Date:** 2026-10-13
**Purpose:** Document publicly available datasets for potential use in HazGuard training

---

## Dataset 1: Water Distribution Leak Detection (Zenodo)

**Source:** https://zenodo.org/records/18631450
**Publication:** "Self-supervised acoustic leakage detection for water distribution systems"
**Published:** February 13, 2026
**License:** Open (Zenodo dataset)
**Size:** 5.7 MB total

### Description
- 1000 acoustic data clips collected from outdoor leakage detection training base
- Located in Dongguan, Southern China
- Used for deep learning based leakage detection models

### Composition
- **Leak folder:** 500 one-second audio clips with detailed leak labels
- **No leak folder:** 386 one-second audio clips with detailed no-leak labels
- **Environmental noise folder:** 114 one-second audio clips (mostly from dlmeasure.com)

### Label Format
- Leaks: `Pipe Material-Region-Pressure in MPa-Flow Rate in m/s-Collection Device`
- Noise: `Noise Category-Region-Collection Device`
- Missing information denoted as NA

### Sensor Information
- **Unknown sensor type** (likely air-coupled microphone)
- **Unknown sampling rate** (need to inspect files)
- **Unknown frequency response**

### Compatibility with HazGuard
**DOMAIN MISMATCH WARNING:**
- These are likely air-coupled microphone recordings
- HazGuard uses contact piezo sensor with different frequency response
- Cannot assume direct interchangeability
- May be useful for preliminary transfer learning experiments only

### Action Required
- Download and inspect actual sampling rate
- Verify sensor type and frequency response
- Document if resampling to 4000 Hz is feasible
- Test if features transfer to piezo domain

---

## Dataset 2: Benchmarking Dataset for Leak Detection (Mendeley Data)

**Source:** https://data.mendeley.com/datasets/tbrnp6vrnj/1
**Publication:** "Benchmarking dataset for leak detection and localization in water distribution systems"
**Published:** December 12, 2022
**License:** CC BY 4.0 (Open Access)
**Size:** Not specified

### Description
- 280 sensory measurements from laboratory-scale water distribution testbed
- 47 m long testbed, 152.4 mm diameter PVC pipes
- Controlled leak experiments

### Sensors
- **2 Accelerometers (A1, A2):** 51.2 kHz sampling rate
- **2 Hydrophones (H1, H2):** 8 kHz sampling rate
- **2 Dynamic Pressure Sensors (P1, P2):** 51.2 kHz sampling rate

### Leak Types
- Longitudinal Crack (LC)
- Circumferential Crack (CC)
- Gasket Leak (GL)
- Orifice Leak (OL)
- No-leak (NL)

### Network Topologies
- Looped (LO)
- Branched (BR)

### Background Conditions
- Flow conditions: 0 L/s, 0.18 L/s, 0.47 L/s, Transient
- Noise conditions: With noise (N), Without noise (NN)

### Recording Duration
- 30 seconds per measurement

### Compatibility with HazGuard
**PARTIAL COMPATIBILITY:**
- Hydrophone data at 8 kHz is closest to HazGuard's 4 kHz
- Hydrophone is water-coupled, closer to contact piezo than air microphone
- Still different sensor physics (hydrophone vs piezo)
- Can be downsampled to 4 kHz
- Most suitable for preliminary experiments among public datasets

### Action Required
- Download hydrophone data (H1, H2 folders)
- Convert .raw format using provided Python script
- Downsample from 8 kHz to 4 kHz
- Test feature transferability

---

## Dataset 3: IDMT-ISA Compressed Air Dataset (Zenodo)

**Source:** https://zenodo.org/records/7551606
**Publication:** IDMT-ISA-Compressed-Air (IICA) dataset
**License:** Open (Zenodo dataset)
**Size:** ~22 GB total (7-7.6 GB per leak type)

### Description
- Compressed air leak detection with acoustic emissions
- Simulated industrial compressed air network
- Audible hearing range recordings

### Leak Types
- Vent Leak
- Vent Leak Low Pressure
- Tube Leak

### Recording Specifications
- **Sampling Rate:** 48 kHz
- **Resolution:** 32-bit
- **Channels:** Mono
- **Duration:** 30 seconds per file
- **Total Files:** 5592

### Microphones
- 4 Earthworks M30 omnidirectional measurement microphones
- Different configurations per recording

### Background Noise
- Industrial background noises played via external loudspeakers
- Two different volumes during recording

### Compatibility with HazGuard
**DOMAIN MISMATCH WARNING:**
- Air-coupled microphones (Earthworks M30)
- 48 kHz sampling rate (12x HazGuard's 4 kHz)
- Compressed air leaks vs water pipe leaks (different physics)
- Large file size may be impractical

### Action Required
- Evaluate if compressed air leak signatures transfer to water pipe leaks
- Consider if only subset needed for preliminary experiments
- Downsampling to 4 kHz would lose high-frequency content

---

## Dataset 4: MIMII Dataset (Zenodo)

**Source:** https://zenodo.org/records/3384388
**Publication:** "Sound Dataset for Malfunctioning Industrial Machine Investigation and Inspection"
**Published:** September 20, 2019
**License:** Open (Zenodo dataset)
**Size:** Not specified

### Description
- Industrial machine sounds for fault diagnosis
- Four machine types: valves, pumps, fans, slide rails
- Includes valve leakage sounds

### Recording Specifications
- **Sampling Rate:** 16 kHz
- **Resolution:** 16-bit
- **Channels:** 8-channel microphone array
- **Anomalous sounds:** ~1000 seconds per machine
- **Normal sounds:** 5000-10000 seconds per machine

### Machine Types
- Valves (includes leakage)
- Pumps
- Fans
- Slide rails

### Anomaly Types
- Contamination
- Leakage (valves)
- Rotating unbalance
- Rail damage

### Background Noise
- Factory background noise mixed with machine sounds

### Compatibility with HazGuard
**LIMITED COMPATIBILITY:**
- Valve leakage sounds are relevant
- Air-coupled microphone array
- 16 kHz sampling rate (4x HazGuard's 4 kHz)
- Industrial machinery context different from water pipes
- May be useful for transfer learning experiments

### Action Required
- Extract valve leakage recordings only
- Downsample to 4 kHz
- Test if valve leak signatures transfer to water pipe leaks

---

## Dataset 5: DCASE Challenge Datasets (Zenodo)

**Sources:**
- DCASE 2024 Task 2: https://zenodo.org/records/11259435 (training), https://zenodo.org/records/11363076 (evaluation)
- DCASE 2023 Task 2: https://zenodo.org/records/7882613 (development), https://zenodo.org/records/7860847 (evaluation)
**Publication:** DCASE Challenge Task 2 - Anomalous Sound Detection for Machine Condition Monitoring
**License:** Open (Zenodo dataset)

### Description
- Unsupervised anomalous sound detection for machine condition monitoring
- Normal/anomalous operating sounds of various machines

### Machine Types (DCASE 2024)
- 3DPrinter
- AirCompressor
- BrushlessMotor
- HairDryer
- HoveringDrone
- RoboticArm
- Scanner
- ToothBrush
- ToyCircuit

### Machine Types (DCASE 2023)
- ToyCar
- ToyTrain
- Fan
- Gearbox
- Bearing
- Slide rail
- Valve

### Recording Specifications
- **Sampling Rate:** Varies (typically 16-48 kHz)
- **Duration:** 6-18 seconds per clip
- **Channels:** Single-channel audio

### Compatibility with HazGuard
**LOW COMPATIBILITY:**
- General industrial machine anomaly detection
- Not specifically leak detection
- Different sensor types and sampling rates
- May be useful for anomaly detection methodology only

### Action Required
- Not recommended for direct leak detection training
- May provide anomaly detection methodology insights

---

## Summary and Recommendations

### Most Suitable for Initial Experiments

1. **Mendeley Water Distribution Dataset (Priority 1)**
   - Hydrophone data at 8 kHz (closest to 4 kHz)
   - Water-coupled sensor (closer to piezo than air mic)
   - Controlled leak experiments
   - CC BY 4.0 license
   - **Action:** Download hydrophone folder, convert .raw, downsample to 4 kHz

2. **Zenodo Water Leak Dataset (Priority 2)**
   - Direct water pipe leak recordings
   - Manageable size (5.7 MB)
   - **Action:** Download, inspect sampling rate, test resampling

### Less Suitable but Potentially Useful

3. **MIMII Dataset (Priority 3)**
   - Contains valve leakage sounds
   - **Action:** Extract valve data only, test transfer learning

### Not Recommended for Direct Training

4. **IDMT-ISA Compressed Air Dataset**
   - Too large (22 GB)
   - Different physics (air vs water)
   - Too high sampling rate (48 kHz)

5. **DCASE Datasets**
   - General machine anomaly, not leak-specific
   - Use for methodology only

---

## Critical Notes

### Sensor Domain Mismatch
- All public datasets use air-coupled microphones or hydrophones
- HazGuard uses contact piezo sensor
- Frequency response and coupling physics are different
- **Do not assume direct interchangeability**

### Sampling Rate Differences
- Public datasets: 8 kHz, 16 kHz, 48 kHz
- HazGuard: 4 kHz
- Downsampling required
- High-frequency content (>2 kHz) will be lost

### Recommended Approach
1. Use synthetic data for initial pipeline development
2. Download Mendeley hydrophone data for preliminary experiments
3. Collect real piezo sensor recordings using `RUN_MODE_COLLECT` mode
4. Train final model on real recordings only
5. Use public datasets only for transfer learning initialization

---

**Status:** Documentation complete. No datasets downloaded yet.
**Next Step:** Build preprocessing pipeline for synthetic data, then evaluate public dataset compatibility.
