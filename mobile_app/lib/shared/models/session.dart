class Session {
  final int id;
  final int sessionId;
  final String deviceId;
  final String traineeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? trainerNotes;
  final Map<String, dynamic> sessionMetadata;
  final DateTime createdAt;

  Session({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    required this.traineeId,
    required this.startedAt,
    this.endedAt,
    this.trainerNotes,
    required this.sessionMetadata,
    required this.createdAt,
  });

  bool get isActive => endedAt == null;
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      deviceId: json['device_id'] as String,
      traineeId: json['trainee_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      trainerNotes: json['trainer_notes'] as String?,
      sessionMetadata: json['session_metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'device_id': deviceId,
      'trainee_id': traineeId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'trainer_notes': trainerNotes,
      'session_metadata': sessionMetadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SessionSummary {
  final int id;
  final int sessionId;
  final int deviceSessionId;
  final String deviceId;
  final String traineeId;
  final int? durationSeconds;
  final int? windows;
  final int? leakEvents;
  final int? gasEvents;
  final int? wetEvents;
  final int? heatEvents;
  final int? uvEvents;
  final int? noiseWindows;
  final double? maxLeakProbability;
  final String? firmwareVersion;
  final Map<String, dynamic> rawPayload;
  final DateTime serverTimestamp;

  SessionSummary({
    required this.id,
    required this.sessionId,
    required this.deviceSessionId,
    required this.deviceId,
    required this.traineeId,
    this.durationSeconds,
    this.windows,
    this.leakEvents,
    this.gasEvents,
    this.wetEvents,
    this.heatEvents,
    this.uvEvents,
    this.noiseWindows,
    this.maxLeakProbability,
    this.firmwareVersion,
    required this.rawPayload,
    required this.serverTimestamp,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      deviceSessionId: json['device_session_id'] as int,
      deviceId: json['device_id'] as String,
      traineeId: json['trainee_id'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      windows: json['windows'] as int?,
      leakEvents: json['leak_events'] as int?,
      gasEvents: json['gas_events'] as int?,
      wetEvents: json['wet_events'] as int?,
      heatEvents: json['heat_events'] as int?,
      uvEvents: json['uv_events'] as int?,
      noiseWindows: json['noise_windows'] as int?,
      maxLeakProbability: (json['max_leak_probability'] as num?)?.toDouble(),
      firmwareVersion: json['firmware_version'] as String?,
      rawPayload: json['raw_payload'] as Map<String, dynamic>? ?? {},
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'device_session_id': deviceSessionId,
      'device_id': deviceId,
      'trainee_id': traineeId,
      'duration_seconds': durationSeconds,
      'windows': windows,
      'leak_events': leakEvents,
      'gas_events': gasEvents,
      'wet_events': wetEvents,
      'heat_events': heatEvents,
      'uv_events': uvEvents,
      'noise_windows': noiseWindows,
      'max_leak_probability': maxLeakProbability,
      'firmware_version': firmwareVersion,
      'raw_payload': rawPayload,
      'server_timestamp': serverTimestamp.toIso8601String(),
    };
  }
}
