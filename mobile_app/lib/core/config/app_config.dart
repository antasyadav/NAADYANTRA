import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration
  static const String defaultApiBaseUrl = 'https://hazguard.onrender.com';
  static const String productionApiBaseUrl = 'https://hazguard.onrender.com';
  static const String localApiBaseUrl = 'http://10.0.2.2:8000';

  // Connection Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Polling Intervals
  static const Duration liveInspectionPollInterval = Duration(seconds: 5);
  static const Duration statusRefreshInterval = Duration(seconds: 30);

  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration deviceOfflineThreshold = Duration(minutes: 5);

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;

  // App Info
  static const String appName = 'NAADYANTRA';
  static const String appVersion = '1.0.0';

  // Debug Mode
  static bool get isDebugMode => kDebugMode;

  // Sensor Semantics - These must match firmware documentation
  static const String gasSensorNote =
      'Baseline-relative ADC delta (not ppm or %LEL)';
  static const String leakProbabilityNote =
      'Model score (not calibrated probability)';
  static const String disabledSensorNote = 'Sensor disabled in firmware';

  // Safety Disclaimer
  static const String safetyDisclaimer =
      'This is a training aid only. Not a certified gas detector or safety instrument.';
}
