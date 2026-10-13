/// Dashboard models — mapped to backend /api/v1/dashboard/* responses.
class DashboardOverview {
  final int totalSessions;
  final int totalDevices;
  final int totalTrainees;
  final int totalEvents;
  final int recentSessionsCount;
  final int activeDevicesCount;

  DashboardOverview({
    required this.totalSessions,
    required this.totalDevices,
    required this.totalTrainees,
    required this.totalEvents,
    required this.recentSessionsCount,
    required this.activeDevicesCount,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalDevices: json['total_devices'] as int? ?? 0,
      totalTrainees: json['total_trainees'] as int? ?? 0,
      totalEvents: json['total_events'] as int? ?? 0,
      recentSessionsCount: json['recent_sessions_count'] as int? ?? 0,
      activeDevicesCount: json['active_devices_count'] as int? ?? 0,
    );
  }
}

class RecentActivityItem {
  final String type; // 'session' or 'event'
  final DateTime timestamp;
  final String deviceId;
  final String? traineeId;
  final Map<String, dynamic> details;

  RecentActivityItem({
    required this.type,
    required this.timestamp,
    required this.deviceId,
    this.traineeId,
    required this.details,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      type: json['type'] as String? ?? 'event',
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['device_id'] as String? ?? 'unknown',
      traineeId: json['trainee_id'] as String?,
      details: json['details'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Human-readable title derived from the activity type and details.
  String get title {
    if (type == 'session') {
      final sessionId = details['session_id'];
      final status = details['status'] as String? ?? 'completed';
      return 'Session #$sessionId ${status == 'active' ? 'Started' : 'Completed'}';
    }
    if (type == 'event') {
      final alert = details['alert'] as String? ?? 'OK';
      final cause = details['cause'] as String?;
      if (alert == 'DANGER' || alert == 'CAUTION') {
        return 'Acoustic Anomaly: ${cause ?? alert}';
      }
      return 'Telemetry Event Recorded';
    }
    return 'Recent Activity';
  }

  /// Subtitle line from device and trainee context.
  String get subtitle {
    final parts = <String>[];
    parts.add('Device: $deviceId');
    if (traineeId != null) parts.add('Trainee: $traineeId');
    return parts.join(' · ');
  }
}
