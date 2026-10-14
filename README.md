# HazGuard

HazGuard is an ESP32-based AI-assisted diagnostic sensing and vocational training platform for SIH 2026 (Problem Statement SIH26244).

## Overview

This repository contains:
- **Backend** (`backend/`): FastAPI-based server with device authentication, session management, and assessment APIs
- **Mobile App** (`mobile_app/`): Flutter-based trainee-facing mobile application
- **Firmware** (`leak_detector.ino`): ESP32 firmware for device control and sensor data logging

## Components

### Backend

The backend provides:
- **Firmware-compatible ingestion endpoint** (`/api/log`) for ESP32 devices
- **Device authentication** using bcrypt-hashed device keys
- **Session management** with event timeline and summary tracking
- **Trainee management** with assessment workflows
- **Dashboard APIs** for trainer/admin monitoring
- **Assessment rubrics** with evidence-based scoring
- **Audit logging** and operational diagnostics
- **JWT-based authentication** for trainers and admins

**Status**: ✅ Complete (37/37 tests passing)
**Documentation**: See [backend/README.md](backend/README.md) or [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md)

### Mobile App

The mobile app provides:
- **Device connectivity monitoring**
- **Live inspection data viewing**
- **Session history and results**
- **Assessment and feedback viewing**
- **Offline data caching**
- **Secure authentication**

**Status**: ✅ Foundation Complete (Authentication, Navigation, API Integration Working)
**Documentation**: See [mobile_app/README.md](mobile_app/README.md) or [mobile_app/IMPLEMENTATION_REPORT.md](mobile_app/IMPLEMENTATION_REPORT.md)

### Firmware

The ESP32 firmware provides:
- **Piezo-based acoustic/vibration sensing**
- **MQ-family gas sensing**
- **Moisture sensing**
- **Optional MLX90614 infrared temperature and GUVA-S12SD UV sensing**
- **Wi-Fi HTTP(S) logging to backend**
- **Physical session start/stop controls**
- **OLED, LED, buzzer and vibration feedback**

**Status**: ✅ Existing (version 1.1.0)
**File**: `leak_detector.ino`

## Current Status

### Backend
- **Test Results**: ✅ 37/37 tests passing
- **Migrations**: ✅ Verified with fresh database
- **Startup**: ✅ Successful
- **Firmware API**: ✅ Verified with curl
- **Physical ESP32**: ❌ NOT TESTED (requires hardware)

### Mobile App
- **Architecture**: ✅ Complete
- **Authentication**: ✅ Complete
- **Navigation**: ✅ Complete
- **API Integration**: ✅ Complete
- **Core Screens**: ✅ Complete
- **Feature Screens**: ⚠️ Partial (placeholders, repositories ready)
- **Physical ESP32**: ❌ NOT TESTED (requires hardware)

### Firmware
- **Version**: 1.1.0
- **Hardware Integration**: ❌ NOT TESTED (requires hardware)

## Quick Start

### Backend Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your values

# Run migrations
python -m alembic upgrade head

# Create admin user
python seed_admin.py

# Start server
python -m backend.main
```

Backend will run at `http://0.0.0.0:8000`

See [backend/README.md](backend/README.md) for detailed backend documentation.

### Mobile App Setup

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run
```

See [mobile_app/README.md](mobile_app/README.md) for detailed mobile app documentation.

### Firmware Setup

1. Open `leak_detector.ino` in Arduino IDE
2. Configure WiFi and backend URL in firmware settings
3. Flash to ESP32 device
4. Connect device to power and network

## Security Notes

**⚠️ CRITICAL**: The firmware uses `secure.setInsecure()` which disables certificate verification. This is unsafe for production. The firmware must be updated to use proper certificate verification before production deployment.

**Default Credentials (MUST BE CHANGED IN PRODUCTION)**:
- Backend admin: username `admin`, password `admin123`
- Device key: `dev-key-123`

**Sensor Data Semantics**:
- Gas readings are baseline-relative ADC delta, NOT ppm or %LEL
- Leak probability is a model score, NOT calibrated probability
- Heat and UV sensors are DISABLED by default in firmware
- This is a training aid, NOT a certified safety instrument

## Technology Stack

### Backend
- **Framework**: FastAPI 0.115.0
- **Database**: SQLAlchemy 2.0.35 with SQLite
- **Migrations**: Alembic 1.13.3
- **Authentication**: JWT (python-jose) + bcrypt
- **Validation**: Pydantic 2.10.5

### Mobile App
- **Framework**: Flutter 3.47.2 (Dart 3.13.2)
- **State Management**: Riverpod 2.6.1
- **Navigation**: GoRouter 14.8.1
- **HTTP Client**: Dio 5.11.1
- **Local Storage**: SQLite + Flutter Secure Storage

### Firmware
- **Platform**: ESP32-S3
- **Sensors**: Piezo, MQ gas, moisture, optional IR temp and UV
- **Communication**: Wi-Fi HTTP(S)

## Test Results

### Backend
- **Automated Tests**: 37/37 passing ✅
- Run: `pytest tests/test_backend.py -v`

### Mobile App
- **Widget Tests**: 1/1 passing ✅
- Run: `cd mobile_app && flutter test`

### Physical ESP32
- **Hardware Integration**: NOT TESTED ❌ (requires hardware)

## Documentation

- [Backend Implementation Report](IMPLEMENTATION_REPORT.md)
- [Mobile App Implementation Report](mobile_app/IMPLEMENTATION_REPORT.md)
- [Backend API Documentation](http://localhost:8000/docs) (when server running)

## Safety Disclaimer

**This is a training aid only. Not a certified gas detector or safety instrument.**

The system is designed for vocational training in controlled environments. It should not be used for actual safety monitoring or gas detection in real-world scenarios.

## Project Structure

```
HazGuard/
├── backend/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration settings
│   ├── database.py          # SQLAlchemy models and database session
│   ├── auth.py              # Authentication and authorization
│   ├── schemas.py           # Pydantic request/response models
│   └── routers/
│       ├── __init__.py
│       ├── health.py        # Health, readiness, system info
│       ├── ingestion.py     # Firmware /api/log endpoint
│       ├── devices.py       # Device management
│       ├── sessions.py      # Session management with CSV export
│       ├── trainees.py      # Trainee management
│       ├── events.py        # Event and summary APIs
│       ├── auth.py          # Login, refresh, logout
│       ├── assessments.py   # Rubrics and assessments
│       ├── dashboard.py     # Dashboard overview and trends
│       └── audit.py         # Audit logs and diagnostics
├── mobile_app/
│   ├── lib/
│   │   ├── app/             # App entry point and routing
│   │   ├── core/            # Configuration, network, storage, theme
│   │   ├── features/        # Feature modules (auth, home, sessions, etc.)
│   │   ├── shared/          # Models, services, widgets
│   │   └── main.dart        # Flutter entry point
│   ├── assets/              # Images and icons
│   ├── test/                # Widget tests
│   └── pubspec.yaml         # Flutter dependencies
├── alembic/
│   ├── env.py               # Alembic environment
│   ├── script.py.mako       # Migration template
│   └── versions/            # Database migrations
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # Test fixtures
│   └── test_backend.py      # Integration tests
├── alembic.ini              # Alembic configuration
├── requirements.txt         # Python dependencies
├── .env                     # Environment variables (not committed)
├── .env.example             # Environment template
├── seed_admin.py            # Admin user creation script
├── leak_detector.ino        # ESP32 firmware
├── README.md                # This file
└── IMPLEMENTATION_REPORT.md # Backend implementation report
```

## Installation

### Backend Setup

#### Prerequisites
- Python 3.11+
- pip

#### Steps
1. **Install dependencies**:
```bash
pip install -r requirements.txt
```

2. **Configure environment variables**:
```bash
cp .env.example .env
# Edit .env with your values
```

3. **Generate device key hash**:
```bash
python -c "from passlib.context import CryptContext; import bcrypt; print(bcrypt.hashpw(b'your-device-key', bcrypt.gensalt()).decode())"
```

4. **Run database migrations**:
```bash
python -m alembic upgrade head
```

5. **Create admin user**:
```bash
python seed_admin.py
```

Default credentials:
- Username: `admin`
- Password: `admin123` (CHANGE IN PRODUCTION!)

### Mobile App Setup

#### Prerequisites
- Flutter SDK 3.13.2+
- Android Studio or VS Code with Flutter extension
- Android SDK for Android development

#### Steps
1. **Navigate to mobile app directory**:
```bash
cd mobile_app
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Configure API URL** (optional):
   - App defaults to `http://10.0.2.2:8000` for Android emulator
   - For physical devices, use your computer's LAN IP
   - Can be changed in app settings

4. **Run on emulator or device**:
```bash
flutter run
```

## Running the Application

### Backend

#### Development
```bash
python -m backend.main
```

#### Production
```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Mobile App

#### Android Emulator
```bash
cd mobile_app
flutter run
```

#### Physical Android Device
```bash
cd mobile_app
flutter devices
flutter run -d <device-id>
```

#### Android APK Build
```bash
cd mobile_app
flutter build apk --debug
flutter build apk --release
```

## API Documentation

Once the server is running:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## API Endpoints

### Health & System

- `GET /health` - Liveness check
- `GET /ready` - Readiness check (database status)
- `GET /api/v1/system/info` - System information

### Firmware Ingestion (ESP32 Compatible)

- `POST /api/log?trainee={trainee_id}&session={session_id}&kind={kind}`
  - Headers: `X-Device-Key: {device_key}`
  - Kind: `event` or `summary`
  - Returns HTTP 200 for accepted or duplicate records

### Device Management

- `POST /api/v1/devices/register` - Register/update device (admin)
- `GET /api/v1/devices` - List devices (trainer/admin)
- `GET /api/v1/devices/{device_id}` - Get device details (trainer/admin)
- `GET /api/v1/devices/{device_id}/status` - Device status (trainer/admin)
- `PATCH /api/v1/devices/{device_id}` - Update device (admin)

### Sessions

- `GET /api/v1/sessions` - List sessions with filters (trainer/admin)
- `GET /api/v1/sessions/{session_id}` - Get session details (trainer/admin)
- `GET /api/v1/sessions/{session_id}/events` - Session event timeline (trainer/admin)
- `GET /api/v1/sessions/{session_id}/summary` - Session summary (trainer/admin)
- `GET /api/v1/sessions/{session_id}/export` - CSV export (trainer/admin)
- `PATCH /api/v1/sessions/{session_id}` - Update session notes (trainer/admin)

### Trainees

- `POST /api/v1/trainees` - Create trainee (trainer/admin)
- `GET /api/v1/trainees` - List trainees (trainer/admin)
- `GET /api/v1/trainees/{trainee_id}` - Get trainee details (trainer/admin)
- `PATCH /api/v1/trainees/{trainee_id}` - Update trainee (admin)
- `GET /api/v1/trainees/{trainee_id}/sessions` - Trainee sessions (trainer/admin)
- `GET /api/v1/trainees/{trainee_id}/assessments` - Trainee assessments (trainer/admin)

### Events

- `GET /api/v1/events` - List events with filters (trainer/admin)
- `GET /api/v1/events/{event_id}` - Get event details (trainer/admin)
- `GET /api/v1/summaries` - List session summaries (trainer/admin)

### Authentication

- `POST /api/v1/auth/login` - Login and get access token
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/me` - Get current user info

### Assessments

- `GET /api/v1/assessment-rubrics` - List rubrics (trainer/admin)
- `POST /api/v1/assessment-rubrics` - Create rubric (admin)
- `GET /api/v1/assessment-rubrics/{rubric_id}` - Get rubric (trainer/admin)
- `POST /api/v1/assessments` - Create assessment (trainer/admin)
- `GET /api/v1/assessments` - List assessments (trainer/admin)
- `GET /api/v1/assessments/{assessment_id}` - Get assessment (trainer/admin)
- `POST /api/v1/assessments/{assessment_id}/review` - Trainer review (trainer/admin)
- `GET /api/v1/assessments/{assessment_id}/audit` - Assessment audit (trainer/admin)

### Dashboard

- `GET /api/v1/dashboard/overview` - Overview statistics (trainer/admin)
- `GET /api/v1/dashboard/recent-activity` - Recent activity (trainer/admin)
- `GET /api/v1/dashboard/trends` - Time-bucketed trends (trainer/admin)
- `GET /api/v1/dashboard/device-health` - Device health (trainer/admin)
- `GET /api/v1/dashboard/alerts` - Recorded alerts (trainer/admin)

### Audit & Diagnostics

- `GET /api/v1/audit-logs` - Audit history (admin)
- `GET /api/v1/diagnostics/ingestion` - Ingestion statistics (admin)
- `GET /api/v1/diagnostics/database` - Database health (admin)

## ESP32 Integration

### Firmware Configuration

Update the firmware settings in `leak_detector.ino`:

```cpp
#define BACKEND_URL      "http://YOUR_COMPUTER_IP:8000"
#define DEVICE_KEY       "your-device-key"
#define DEVICE_ID        "SIH-DEV-01"
#define TRAINEE_ID       "T001"
```

### Device Registration

1. Register the device via API:
```bash
curl -X POST http://localhost:8000/api/v1/devices/register \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "SIH-DEV-01",
    "name": "Leak Detector 01",
    "device_key": "your-device-key"
  }'
```

2. The firmware will automatically send events to `/api/log` with the device key.

### Testing Physical Integration

1. Start the backend server
2. Flash the ESP32 with configured firmware
3. Connect ESP32 to the same network as the backend
4. Press the BOOT button to start a session
5. Verify events appear in the database via API

## Testing

### Backend Tests

```bash
pytest tests/test_backend.py -v
```

**Results**: 37/37 tests passing ✅

### Mobile App Tests

```bash
cd mobile_app
flutter test
```

**Results**: 1/1 widget test passing ✅

### Test Coverage

**Backend tests cover**:
- Health and readiness endpoints
- Device authentication
- Firmware event and summary ingestion
- Duplicate handling
- User authentication
- Device, session, trainee, and event management
- Assessment and rubric APIs
- Dashboard APIs
- Audit and diagnostics

**Mobile app tests cover**:
- App rendering
- Navigation flow
- Authentication flow (manual testing)

### Physical Hardware Testing

**Status**: NOT TESTED ❌

Requires:
- ESP32 hardware
- Physical sensor setup
- Network configuration
- Lab supervision for safety

## Database Schema

### Tables

- `users` - Admin and trainer accounts
- `devices` - Device metadata
- `device_credentials` - Device authentication keys (hashed)
- `trainees` - Trainee records
- `sessions` - Training sessions
- `events` - Individual sensor events
- `session_summaries` - Session summaries from firmware
- `assessment_rubrics` - Assessment scoring rules
- `assessments` - Trainee assessments
- `trainer_reviews` - Trainer assessment reviews
- `audit_logs` - Administrative audit trail
- `ingestion_errors` - Ingestion error tracking

### Key Features

- Composite indexes for common query patterns
- Foreign key constraints for data integrity
- JSON columns for flexible metadata
- Idempotency keys for duplicate detection
- UTC-aware timestamps throughout

## Security

### Device Authentication

- Device keys are bcrypt-hashed in the database
- Every firmware request requires `X-Device-Key` header
- Auto-registration available for initial setup (configure device key hash in .env)

### User Authentication

- JWT tokens with configurable expiration
- Role-based access control (admin, trainer)
- Bcrypt password hashing
- Separate device and user authentication

### Best Practices

- Store secrets in environment variables
- Use HTTPS in production
- Implement certificate verification
- Configure request size limits
- Rate-limit sensitive endpoints
- Never commit credentials to version control

## Deployment

### Production Checklist

- [ ] Change SECRET_KEY to a strong random value
- [ ] Change admin password
- [ ] Use PostgreSQL instead of SQLite
- [ ] Enable HTTPS with valid certificates
- [ ] Configure CORS appropriately
- [ ] Set up regular database backups
- [ ] Configure monitoring and logging
- [ ] Remove or secure `/docs` and `/redoc` endpoints
- [ ] Set environment to `production`
- [ ] Configure firewall rules

### Environment Variables

```bash
DATABASE_URL=postgresql://user:password@host/dbname
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
ENVIRONMENT=production
SECRET_KEY=strong-random-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
DEVICE_KEY_HASH=$2b$12$bcrypt-hash-of-device-key
DEVICE_ONLINE_THRESHOLD_SECONDS=300
```

## Troubleshooting

### Database Migration Issues

```bash
# Check current version
python -m alembic current

# Rollback if needed
python -m alembic downgrade -1

# Reset (WARNING: deletes data)
python -m alembic downgrade base
python -m alembic upgrade head
```

### Device Authentication Failures

1. Verify device key hash matches
2. Check device is registered and active
3. Verify X-Device-Key header is sent correctly

### Connection Issues

1. Check ESP32 and backend are on same network
2. Verify firewall allows traffic on port 8000
3. Check BACKEND_URL in firmware includes correct IP

## Limitations and Future Improvements

### Current Limitations

1. **Duplicate Detection**: Based on payload fingerprint. Future firmware should include `boot_id` + monotonic `seq` for perfect deduplication.
2. **Firmware Queue**: In-memory queue (40 items) is not persistent. Recommend flash-based queue for production.
3. **Session ID Collisions**: Session IDs are per-device, not globally unique. Use device filter when querying.
4. **Sensor Calibration**: Thresholds are not validated. Calibrate with reference instruments.
5. **Real-time Status**: Device online status is inferred from last-seen threshold, not real-time connectivity.

### Recommended Firmware Improvements

1. Add `boot_id` field (random at startup)
2. Add monotonic `seq` field (increment per event)
3. Implement persistent flash queue
4. Add sensor availability flags
5. Add calibration validity flags
6. Replace `secure.setInsecure()` with proper certificate verification
7. Add signal quality indicators

### Backend Improvements

1. WebSocket support for real-time updates
2. Advanced analytics and reporting
3. Multi-tenant support
4. Enhanced security with 2FA

### Mobile App Improvements

1. Complete live inspection monitoring screen
2. Implement session list with real data
3. Implement session detail with event timeline
4. Add assessment viewing functionality
5. Implement comprehensive help documentation
6. Add push notifications
7. Implement background sync service
8. Add WebSocket support for real-time updates
9. Implement Hindi localization
10. Add offline editing capabilities

## License

This project is developed for SIH 2026 (Problem Statement SIH26244).

## Support

For issues or questions:
1. Check the API documentation at `/docs`
2. Review the troubleshooting section
3. Check firmware configuration in `leak_detector.ino`
4. Verify database migrations are current

## Acknowledgments

- Built for Smart India Hackathon 2026
- ESP32 firmware reference provided
- FastAPI, SQLAlchemy, and Alembic communities
