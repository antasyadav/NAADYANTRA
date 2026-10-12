class Device {
  final int id;
  final String deviceId;
  final String? name;
  final String? firmwareVersion;
  final DateTime? lastSeenAt;
  final Map<String, dynamic> deviceMetadata;
  final DateTime createdAt;
  final bool isActive;

  Device({
    required this.id,
    required this.deviceId,
    this.name,
    this.firmwareVersion,
    this.lastSeenAt,
    required this.deviceMetadata,
    required this.createdAt,
    required this.isActive,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      name: json['name'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      deviceMetadata: json['device_metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'name': name,
      'firmware_version': firmwareVersion,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'device_metadata': deviceMetadata,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class DeviceStatus {
  final String deviceId;
  final DateTime? lastSeenAt;
  final String? firmwareVersion;
  final bool isOnline;
  final int recentActivityCount;
  final String? lastError;

  DeviceStatus({
    required this.deviceId,
    this.lastSeenAt,
    this.firmwareVersion,
    required this.isOnline,
    required this.recentActivityCount,
    this.lastError,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['device_id'] as String,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      firmwareVersion: json['firmware_version'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      recentActivityCount: json['recent_activity_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'firmware_version': firmwareVersion,
      'is_online': isOnline,
      'recent_activity_count': recentActivityCount,
      'last_error': lastError,
    };
  }
}
