# NAADYANTRA Mobile App

Flutter mobile application for the NAADYANTRA diagnostic sensing and vocational training platform.

## Overview

The NAADYANTRA mobile app is the trainee-facing interface for the ESP32-based diagnostic sensing platform. It provides:

- Device connectivity monitoring
- Live inspection data viewing
- Session history and results
- Assessment and feedback viewing
- Offline data caching
- Secure authentication

## Technology Stack

- **Framework**: Flutter 3.47.2 with Dart 3.13.2
- **State Management**: Riverpod 2.6.1
- **Navigation**: GoRouter 14.8.1
- **HTTP Client**: Dio 5.11.1
- **Local Storage**: SQLite (sqflite), Flutter Secure Storage
- **Network**: connectivity_plus
- **Charts**: fl_chart
- **Localization**: flutter_localization

## Project Structure

```
lib/
├── app/
│   ├── app.dart              # Main app widget
│   └── router.dart           # Navigation configuration
├── core/
│   ├── config/               # App configuration
│   ├── constants/            # API constants
│   ├── errors/               # Custom exceptions
│   ├── network/              # API client
│   ├── storage/              # Local database & secure storage
│   ├── theme/                # App theme
│   └── utils/                # Utility functions
├── features/
│   ├── authentication/       # Login flow
│   ├── home/                 # Home screen with tabs
│   ├── devices/              # Device management
│   ├── inspection/           # Live inspection monitoring
│   ├── sessions/             # Session history and details
│   ├── assessments/          # Assessment viewing
│   ├── settings/             # App settings
│   └── help/                 # Help and troubleshooting
├── shared/
│   ├── models/               # Data models
│   ├── services/             # Repositories and providers
│   └── widgets/              # Reusable widgets
└── main.dart                 # App entry point
```

## Setup Instructions

### Prerequisites

- Flutter SDK 3.13.2 or higher
- Android Studio or VS Code with Flutter extension
- Android SDK for Android development
- Running NAADYANTRA backend server

### Installation

1. Navigate to the mobile app directory:
```bash
cd mobile_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API URL (optional):
The app defaults to `http://10.0.2.2:8000` for Android emulator. For physical devices, update the API URL in the settings screen or modify `lib/core/config/app_config.dart`.

### Running the App

#### Android Emulator
```bash
flutter run
```

#### Physical Android Device
1. Enable USB debugging on your device
2. Connect device via USB
3. Run:
```bash
flutter devices
flutter run -d <device-id>
```

#### Android APK Build
```bash
flutter build apk --debug
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/`

## Backend Integration

The mobile app integrates with the NAADYANTRA FastAPI backend. Ensure the backend is running before using the app.

### Default Configuration

- **API Base URL**: `http://10.0.2.2:8000` (Android emulator)
- **Physical Device URL**: Use your computer's LAN IP (e.g., `http://192.168.1.100:8000`)
- **Authentication**: JWT-based with role-based access control

### API Endpoints Used

- `POST /api/v1/auth/login` - User authentication
- `GET /api/v1/devices` - Device listing
- `GET /api/v1/devices/{device_id}/status` - Device status
- `GET /api/v1/sessions` - Session history
- `GET /api/v1/sessions/{session_id}` - Session details
- `GET /api/v1/sessions/{session_id}/events` - Session events
- `GET /api/v1/sessions/{session_id}/summary` - Session summary
- `GET /api/v1/assessments` - Assessment history

## Features

### Authentication
- Secure login with username/password
- JWT token storage in secure storage
- Automatic token refresh
- Logout functionality

### Home Screen
- Device status overview
- Recent activity feed
- Quick statistics
- Navigation to main features

### Inspection
- Live device monitoring
- Real-time sensor readings
- Event timeline
- Alert notifications

### Session History
- Paginated session list
- Session details with summary
- Event timeline view
- Filter by device, trainee, date

### Settings
- API URL configuration
- Language selection
- Theme preference
- Cache management
- Help and support

## Sensor Semantics

The app correctly represents sensor data based on firmware documentation:

- **Gas Reading**: Baseline-relative ADC delta (not ppm or %LEL)
- **Leak Probability**: Model score (not calibrated probability)
- **Heat/UV Sensors**: Marked as unavailable when disabled in firmware
- **Moisture State**: Wet-state indicator

## Security Notes

- All authentication tokens stored securely using Flutter Secure Storage
- API calls use HTTPS in production (configure backend accordingly)
- No passwords or sensitive data logged
- Certificate verification required for production (firmware currently uses insecure mode)

## Safety Disclaimer

**This is a training aid only. Not a certified gas detector or safety instrument.**

The app is designed for vocational training in controlled environments. It should not be used for actual safety monitoring or gas detection in real-world scenarios.

## Testing

Run the widget test:
```bash
flutter test
```

Run analysis:
```bash
flutter analyze
```

Format code:
```bash
dart format .
```

## Troubleshooting

### App cannot connect to backend
- Ensure backend server is running
- Check API URL in settings (use LAN IP for physical devices)
- Verify device and computer are on same network
- Check firewall settings

### Authentication errors
- Verify backend credentials are correct
- Check backend admin user exists (run `seed_admin.py`)
- Ensure JWT configuration matches backend

### Sensor data not appearing
- Check device is sending data to backend
- Verify device is online in backend
- Check session is active
- Refresh data manually

## Known Limitations

1. **Physical ESP32 Integration**: Not tested - requires actual hardware
2. **Background Sync**: No background service for automatic sync
3. **Push Notifications**: Not implemented
4. **Offline Editing**: Read-only when offline
5. **Real-time Updates**: Uses polling, not WebSockets

## Recommended Backend Improvements

1. Add WebSocket support for real-time updates
2. Implement push notifications for alerts
3. Add offline queue for trainee actions
4. Implement trainee-specific authentication
5. Add device command endpoints (if firmware supports)

## License

This is part of the NAADYANTRA project for SIH 2026.
