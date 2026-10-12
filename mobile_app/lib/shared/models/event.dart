class Event {
  final int id;
  final String deviceId;
  final int sessionId;
  final int internalSessionId;
  final String traineeId;
  final String eventKind;
  final int? deviceTimestamp;
  final DateTime serverTimestamp;
  final int? deviceUptimeMs;
  final String? eventName;
  final String? alert;
  final String? cause;
  final String? modelLabel;
  final double? leakProbability;
  final double? rms;
  final int? gasDelta;
  final double? gasRatio;
  final double? temperature;
  final int? uvDelta;
  final bool? wet;
  final String? firmwareVersion;
  final Map<String, dynamic> rawPayload;
  final String ingestionStatus;

  Event({
    required this.id,
    required this.deviceId,
    required this.sessionId,
    required this.internalSessionId,
    required this.traineeId,
    required this.eventKind,
    this.deviceTimestamp,
    required this.serverTimestamp,
    this.deviceUptimeMs,
    this.eventName,
    this.alert,
    this.cause,
    this.modelLabel,
    this.leakProbability,
    this.rms,
    this.gasDelta,
    this.gasRatio,
    this.temperature,
    this.uvDelta,
    this.wet,
    this.firmwareVersion,
    required this.rawPayload,
    required this.ingestionStatus,
  });

  bool get hasGasData => gasDelta != null || gasRatio != null;
  bool get hasAcousticData => rms != null || leakProbability != null;
  bool get hasMoistureData => wet != null;
  bool get hasTemperatureData => temperature != null;
  bool get hasUvData => uvDelta != null;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      sessionId: json['session_id'] as int,
      internalSessionId: json['internal_session_id'] as int,
      traineeId: json['trainee_id'] as String,
      eventKind: json['event_kind'] as String,
      deviceTimestamp: json['device_timestamp'] as int?,
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
      deviceUptimeMs: json['device_uptime_ms'] as int?,
      eventName: json['event_name'] as String?,
      alert: json['alert'] as String?,
      cause: json['cause'] as String?,
      modelLabel: json['model_label'] as String?,
      leakProbability: json['leak_probability'] as double?,
      rms: json['rms'] as double?,
      gasDelta: json['gas_delta'] as int?,
      gasRatio: json['gas_ratio'] as double?,
      temperature: json['temperature'] as double?,
      uvDelta: json['uv_delta'] as int?,
      wet: json['wet'] as bool?,
      firmwareVersion: json['firmware_version'] as String?,
      rawPayload: json['raw_payload'] as Map<String, dynamic>? ?? {},
      ingestionStatus: json['ingestion_status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'session_id': sessionId,
      'internal_session_id': internalSessionId,
      'trainee_id': traineeId,
      'event_kind': eventKind,
      'device_timestamp': deviceTimestamp,
      'server_timestamp': serverTimestamp.toIso8601String(),
      'device_uptime_ms': deviceUptimeMs,
      'event_name': eventName,
      'alert': alert,
      'cause': cause,
      'model_label': modelLabel,
      'leak_probability': leakProbability,
      'rms': rms,
      'gas_delta': gasDelta,
      'gas_ratio': gasRatio,
      'temperature': temperature,
      'uv_delta': uvDelta,
      'wet': wet,
      'firmware_version': firmwareVersion,
      'raw_payload': rawPayload,
      'ingestion_status': ingestionStatus,
    };
  }
}
