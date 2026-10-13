class PaginatedResponse<T> {
  final int total;
  final int page;
  final int pageSize;
  final List<T> items;
  final bool isFromCache;

  PaginatedResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
    this.isFromCache = false,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      items: (json['items'] as List<dynamic>)
          .map((item) => fromJsonT(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'page_size': pageSize,
      'items': items,
    };
  }
}

class HealthResponse {
  final String status;
  final DateTime timestamp;

  HealthResponse({required this.status, required this.timestamp});

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'timestamp': timestamp.toIso8601String()};
  }
}

class ReadyResponse {
  final String status;
  final String database;
  final DateTime timestamp;

  ReadyResponse({
    required this.status,
    required this.database,
    required this.timestamp,
  });

  factory ReadyResponse.fromJson(Map<String, dynamic> json) {
    return ReadyResponse(
      status: json['status'] as String,
      database: json['database'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'database': database,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SystemInfoResponse {
  final String apiVersion;
  final String applicationVersion;
  final String environment;
  final DateTime serverUtc;

  SystemInfoResponse({
    required this.apiVersion,
    required this.applicationVersion,
    required this.environment,
    required this.serverUtc,
  });

  factory SystemInfoResponse.fromJson(Map<String, dynamic> json) {
    return SystemInfoResponse(
      apiVersion: json['api_version'] as String,
      applicationVersion: json['application_version'] as String,
      environment: json['environment'] as String,
      serverUtc: DateTime.parse(json['server_utc'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'api_version': apiVersion,
      'application_version': applicationVersion,
      'environment': environment,
      'server_utc': serverUtc.toIso8601String(),
    };
  }
}
