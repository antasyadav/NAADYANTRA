# HazGuard (नाद्यन्त्र) — Complete Architecture Guide
> **Written in Easy Language (आसान भाषा में पूरा आर्किटेक्चर गाइड)**  
> *Acoustic Pipeline & Valve Diagnostic System: Hardware Sensor Node → Signal Processing → FastAPI Backend → Flutter Offline-First Mobile App*

---

## 1. Naadyantra Kya Hai? (Overview)

**Naadyantra** basically industrial pipelines (paani, gas, chemical pipes) aur valves ke liye ek **"Acoustic Digital Stethoscope"** ki tarah kaam karta hai.

### Real-Life Analogy:
- Jaise ek doctor stethoscope ko chest par laga kar dil ki abnormal sound sun kar bimari pehchaanta hai...
- Bilkul waise hi, **Naadyantra** pipe ke surface par ek high-sensitivity **Piezo Contact Transducer (Acoustic Sensor)** chipkata hai.
- Jab pipe me koi leak, crack ya valve blockage hoti hai, toh fluid/gas high pressure se bahar nikalte waqt ek specific **ultrasonic/high-frequency sound** create karta hai.
- Naadyantra us sound wave ko pakad kar analyze karta hai aur turant screen par show kar deta hai ki **"Pipe me leak hai ya sab nominal hai"**.

---

## 2. High-Level Architecture Diagram (4 Pillars)

```mermaid
graph TD
    subgraph Layer 1: Hardware Probe [ESP32 Hardware Node]
        Piezo[Piezo Contact Transducer ADC1_CH4]
        Gas[Gas Sensor MQ / Combustible]
        Env[Moisture / Temp Probe]
        FreeRTOS[FreeRTOS ISR 1024 Samples 50% Hop]
        DCFilter[IIR DC-Block Filter R=0.995]
        Piezo --> FreeRTOS
        Gas --> FreeRTOS
        Env --> FreeRTOS
        FreeRTOS --> DCFilter
    end

    subgraph Layer 2: Edge & Signal Processing [Signal Processing]
        DCFilter --> RMSCalc[Acoustic RMS Amplitude Calculation]
        RMSCalc --> ONNX[Acoustic ML / ONNX Classifier]
        ONNX --> TelemetryPacket[Telemetry Payload JSON + Hardware Key]
    end

    subgraph Layer 3: Backend Gateway [FastAPI & Database]
        TelemetryPacket -->|HTTP POST Ingest| IngestAPI[/api/v1/events/ingest]
        IngestAPI --> AuthCheck[Hardware Key & Token Validation]
        AuthCheck --> DB[(SQLite / PostgreSQL Engine)]
        DB --> RESTAPI[REST APIs: Sessions, Devices, Dashboard]
    end

    subgraph Layer 4: Mobile Experience [Flutter Mobile App]
        RESTAPI -->|Dio HTTP Client| Repositories[Repositories: Device, Session, Dashboard]
        Repositories -->|Online Success| CacheSave[Save into Local SQLite Cache]
        Repositories -->|NetworkException / No Internet| LocalCache[(Local SQLite Database sqflite)]
        CacheSave --> UI[Cinematic Light Industrial UI]
        LocalCache -->|Instant Fallback| UI
        UI --> PrecisionGauge[230° Symmetric Arc Gauge]
        UI --> CalibrationBar[Live Calibration Track 400 ADC]
        UI --> OscBuffer[Oscilloscope Telemetry Buffer]
    end
```

---

## 3. Layer-by-Layer Deep Dive (Kaam Kaise Karta Hai?)

---

### Layer 1: Hardware & Physics (ESP32 Sensor Rig)

1. **Piezo Contact Transducer (`ADC1_CH4`)**:
   - Ye sensor pipe ke vibration aur acoustic frequencies ko pakadta hai.
   - ESP32 ka internal 12-bit Analog-to-Digital Converter (ADC) continuous voltage ko **0 se 4095** ke number range me convert karta hai.
2. **IIR DC-Block Filter (`R = 0.995`)**:
   - Sensor se aane wale signal me thoda sa baseline DC voltage drift hota hai.
   - Formula:  
     $$y[n] = x[n] - x[n-1] + R \cdot y[n-1]$$  
     Ye filter unwanted DC noise ko nikal deta hai taaki hume pure acoustic vibration mile.
3. **FreeRTOS Real-Time Sampling (1024-sample window, 50% hop)**:
   - ESP32 me FreeRTOS timer interrupt har cycle me **1024 continuous samples** record karta hai.
   - 50% hop ka matlab hai ki agli calculation pichhli window ke 512 samples ko overlap karti hai, taaki ek millisecond ka leak spike bhi miss na ho.
4. **Multi-Modal Sensors**:
   - **Combustible Gas**: Pipe se bahar aane wali gas ka $\Delta ADC$ aur $R_s/R_0$ ratio.
   - **Moisture**: Conduction probe jo liquid leakage detect karta hai.
   - **Temperature**: Pipe surface thermal monitoring.

---

### Layer 2: Signal Processing & AI/ML Classification

1. **Acoustic RMS (Root Mean Square)**:
   - Acoustic signal ki total energy calculate hoti hai:
     $$RMS = \sqrt{\frac{1}{N} \sum_{i=1}^{N} (sample_i)^2}$$
2. **Leak Anomaly Trigger Threshold (400 ADC)**:
   - **0 – 399 ADC**: Normal laminar flow (Pipe me fluid aaram se beh raha hai).
   - **≥ 400 ADC**: Turbulent orifice leak (Chhota sa hole ya crack jisse high velocity spray nikal raha hai). Turant **ANOMALY DETECTED** trigger hota hai!
3. **Acoustic Resonance Frequency (28 kHz – 39 kHz)**:
   - Pressurized pipe leak hamesha ultrasonic frequency range (28k–39k Hz) me hiss/whistle produce karta hai.
4. **ONNX Machine Learning Model**:
   - Live FFT spectrogram features ONNX neural network model me feed hote hain jo classify karta hai ki sound valve cavitation ka hai ya orifice leak ka.

---

### Layer 3: Backend Gateway (FastAPI REST Server)

1. **Zero Fabrication & Telemetry Ingestion (`/api/v1/events/ingest`)**:
   - Hardware ESP32 node har cycle me apna packet bhejta hai.
   - Hardware key verify hoti hai taaki koi fake packet inject na ho sake.
2. **Session Engine (`/api/v1/sessions`)**:
   - Jab technician pipe inspection start karta hai, ek **Session** create hota hai.
   - Us session me jitne bhi events (RMS, Gas, Temperature, Leak Alerts) aate hain, wo database me session se link ho jaate hain.
   - Inspection khatam hone par backend pure run ka **Session Summary** generate karta hai (Average RMS, Peak Anomaly, Duration).
3. **Dashboard Aggregations (`/api/v1/dashboard/overview`)**:
   - Total registered devices, active nodes, logged inspection sessions calculate karke provide karta hai.

---

### Layer 4: Mobile Experience & Offline-First Engine (Flutter)

Mobile app technician ka field companion hai. Isme 3 sabse badi architectural qualities hain:

#### A. Offline-First SQLite Persistence Engine (`sqflite`)
Jab field me mobile internet chala jata hai ya signal nahi hota:
1. **Network Layer (`api_client.dart`)**:
   - Jab internet disconnected hota hai, Dio network call `NetworkException` raise karti hai.
2. **Repository Fallback (`device_repository.dart` & `session_repository.dart`)**:
   - Repository error throw karne ke bajaye seedhe local database (`LocalDatabase`) me query karti hai.
   - Pehle se cached devices, sessions, events, summaries instantly load ho jaate hain.
3. **Offline Buffer Indicator**:
   - Screen par `OFFLINE BUFFER — DISPLAYING PERSISTED SQLITE CACHE` banner render hota hai, jisse technician ko pata chalta hai ki app smoothly chal rahi hai local storage se.

#### B. Reactive State Management (Riverpod 2.6)
- UI kisi bhi backend ya local database se directly connect nahi hoti.
- Riverpod Providers (`deviceStatusProvider`, `recentEventsProvider`, `isOfflineProvider`) pure state ko streamline karte hain.
- `connectivity_plus` ke stream se app auto-detect karti hai jaise hi internet wapas aaye, aur background sync ho jata hai.

#### C. Cinematic Light Industrial Design System
- **Approved Palette**:
  - `Industrial Ivory (#F7F5F0)`: Clean app canvas.
  - `Pure White (#FFFFFF)`: Elevated high-contrast cards.
  - `Carbon (#252525)`: Bold technical typography.
  - `Burnt Orange (#F07842)`: Primary brand accent.
  - `Dark Burnt Orange (#A94E29)`: High-urgency alert state.
  - `Warm Graphite (#716D67)`: Technical units & captions.
  - `Warm Stone (#E9E5DE)`: Grid lines and dividing rules.
- **Custom Precision Dial Gauge (`_ArcGaugePainter`)**:
  - 230° perfectly symmetric arc.
  - 24 radial scale graduation ticks.
  - 400 ADC leak threshold notch.
  - Dual-layer glowing tip (white core + soft bloom).
- **Oscilloscope Standby Waveform Buffer**:
  - Real-time animated grid for live sampling.

---

## 4. End-to-End Leak Detection Journey (Story Walkthrough)

1. **Step 1: Physical Pipe Leaks**  
   Gas pipe ke joint me 1mm ka micro-crack banta hai. Gas bahar aate waqt 32 kHz par high-energy acoustic noise create karti hai.
2. **Step 2: Sensor Captures Vibration**  
   Pipe se contact me laga Piezo transducer us vibration ko electrical millivolts me convert karta hai.
3. **Step 3: ESP32 FreeRTOS Interrupts**  
   ESP32 ADC1_CH4 par 1024 samples read hote hain. IIR DC-block filter noise nikalta hai. RMS nikal kar value aati hai: **1650 ADC**.
4. **Step 4: Network Ingestion**  
   ESP32 HTTP POST packet bhejta hai: `{ "device_id": "SIH-NODE-01", "rms": 1650.0, "leak_probability": 0.94 }`.
5. **Step 5: FastAPI Validates & Archives**  
   Backend hardware key check karta hai, event ko database me save karta hai, aur alert status `LEAK_DETECTED` mark karta hai.
6. **Step 6: Flutter App Visualizes Live**  
   Flutter app 2 second ke polling interval par update hoti hai.
   - 230° symmetric arc smooth curve me **1650** par rotate hota hai.
   - Glowing tip alert mode me red bloom karti hai.
   - Status pill **ANOMALY DETECTED** dikhata hai.
   - Technician turant pipe valve band karke accident hone se bacha leta hai!

---

## 5. Summary Table

| Component | Technology | Responsibility |
| :--- | :--- | :--- |
| **Edge Hardware** | ESP32 / ESP32-S3 (C++) | 12-bit ADC, FreeRTOS ISR, IIR DC-Block filter, NVS Key |
| **Acoustic AI** | NumPy / SciPy / ONNX | FFT extraction, 28–39 kHz resonance band, leak classification |
| **Backend** | Python FastAPI / SQLAlchemy | Ingestion endpoint, session management, telemetry archive |
| **Mobile Core** | Flutter 3.47+ / Dart 3.13+ | Clean Architecture, Riverpod state, GoRouter navigation |
| **Offline Cache**| SQLite (`sqflite 2.4`) | Persistent local buffer for 100% offline field diagnostics |
| **UI Aesthetics** | CustomPainter / Flutter Canvas| Cinematic light industrial styling, symmetric 230° dials |

---
*HazGuard — Precision Acoustic Pipe & Valve Diagnostics.*
