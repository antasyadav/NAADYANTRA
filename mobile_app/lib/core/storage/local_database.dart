import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'naadyantra.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Devices table
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY,
        device_id TEXT NOT NULL,
        name TEXT,
        firmware_version TEXT,
        last_seen_at TEXT,
        device_metadata TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY,
        session_id INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        trainee_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        trainer_notes TEXT,
        session_metadata TEXT,
        created_at TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Events table
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY,
        device_id TEXT NOT NULL,
        session_id INTEGER NOT NULL,
        internal_session_id INTEGER NOT NULL,
        trainee_id TEXT NOT NULL,
        event_kind TEXT NOT NULL,
        device_timestamp INTEGER,
        server_timestamp TEXT NOT NULL,
        device_uptime_ms INTEGER,
        event_name TEXT,
        alert TEXT,
        cause TEXT,
        model_label TEXT,
        leak_probability REAL,
        rms REAL,
        gas_delta INTEGER,
        gas_ratio REAL,
        temperature REAL,
        uv_delta INTEGER,
        wet INTEGER,
        firmware_version TEXT,
        raw_payload TEXT,
        ingestion_status TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Summaries table
    await db.execute('''
      CREATE TABLE summaries (
        id INTEGER PRIMARY KEY,
        session_id INTEGER NOT NULL,
        device_session_id INTEGER NOT NULL,
        device_id TEXT NOT NULL,
        trainee_id TEXT NOT NULL,
        duration_seconds INTEGER,
        windows INTEGER,
        leak_events INTEGER,
        gas_events INTEGER,
        wet_events INTEGER,
        heat_events INTEGER,
        uv_events INTEGER,
        noise_windows INTEGER,
        max_leak_probability REAL,
        firmware_version TEXT,
        raw_payload TEXT,
        server_timestamp TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_sessions_device_id ON sessions(device_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_trainee_id ON sessions(trainee_id)',
    );
    await db.execute(
      'CREATE INDEX idx_events_session_id ON events(session_id)',
    );
    await db.execute('CREATE INDEX idx_events_device_id ON events(device_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('devices');
    await db.delete('sessions');
    await db.delete('events');
    await db.delete('summaries');
  }

  Future<int> getCacheCount() async {
    final db = await database;
    final sessionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sessions'),
    );
    return sessionCount ?? 0;
  }

  // Cache upsert methods
  Future<void> cacheDevice(Map<String, dynamic> deviceData) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      await db.insert('devices', {
        ...deviceData,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache error - silently continue
    }
  }

  Future<void> cacheDeviceStatus(
    String deviceId,
    Map<String, dynamic> statusData,
  ) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      await db.insert('devices', {
        ...statusData,
        'device_id': deviceId,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache error - silently continue
    }
  }

  Future<void> cacheSession(Map<String, dynamic> sessionData) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      await db.insert('sessions', {
        ...sessionData,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache error - silently continue
    }
  }

  Future<void> cacheEvent(Map<String, dynamic> eventData) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      await db.insert('events', {
        ...eventData,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache error - silently continue
    }
  }

  Future<void> cacheSummary(Map<String, dynamic> summaryData) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      await db.insert('summaries', {
        ...summaryData,
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Cache error - silently continue
    }
  }

  // Cache query methods
  Future<Map<String, dynamic>?> getCachedDevice(String deviceId) async {
    try {
      final db = await database;
      final results = await db.query(
        'devices',
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCachedDeviceStatus(String deviceId) async {
    try {
      final db = await database;
      final results = await db.query(
        'devices',
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
      if (results.isEmpty) return null;
      final device = results.first;
      return {
        'device_id': device['device_id'],
        'last_seen_at': device['last_seen_at'],
        'firmware_version': device['firmware_version'],
        'is_online': _isDeviceOnline(device['last_seen_at'] as String?),
        'recent_activity_count': device['recent_activity_count'] as int? ?? 0,
        'last_error': device['last_error'],
      };
    } catch (e) {
      return null;
    }
  }

  bool _isDeviceOnline(String? lastSeenAt) {
    if (lastSeenAt == null) return false;
    try {
      final lastSeen = DateTime.parse(lastSeenAt);
      final diff = DateTime.now().difference(lastSeen);
      return diff.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedDevices({
    bool? isActive,
    int limit = 50,
  }) async {
    try {
      final db = await database;
      String? where;
      List<dynamic>? whereArgs;

      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }

      final results = await db.query(
        'devices',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'cached_at DESC',
        limit: limit,
      );
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCachedSessions({
    String? deviceId,
    String? traineeId,
    int limit = 50,
  }) async {
    try {
      final db = await database;
      String? where;
      List<dynamic>? whereArgs;

      if (deviceId != null && traineeId != null) {
        where = 'device_id = ? AND trainee_id = ?';
        whereArgs = [deviceId, traineeId];
      } else if (deviceId != null) {
        where = 'device_id = ?';
        whereArgs = [deviceId];
      } else if (traineeId != null) {
        where = 'trainee_id = ?';
        whereArgs = [traineeId];
      }

      final results = await db.query(
        'sessions',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'started_at DESC',
        limit: limit,
      );
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<DateTime?> getLastCacheTime(String table) async {
    try {
      final db = await database;
      final results = await db.rawQuery(
        'SELECT MAX(cached_at) as max_cached FROM $table',
      );
      if (results.isEmpty || results.first['max_cached'] == null) {
        return null;
      }
      return DateTime.parse(results.first['max_cached'] as String);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCachedSession(int sessionId) async {
    try {
      final db = await database;
      final results = await db.query(
        'sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedEvents(int sessionId) async {
    try {
      final db = await database;
      final results = await db.query(
        'events',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'server_timestamp ASC',
      );
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCachedSummary(int sessionId) async {
    try {
      final db = await database;
      final results = await db.query(
        'summaries',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      return null;
    }
  }

  // Cache staleness check
  bool isCacheStale(
    String cachedAt, {
    Duration maxAge = const Duration(hours: 24),
  }) {
    try {
      final cachedTime = DateTime.parse(cachedAt);
      final now = DateTime.now();
      return now.difference(cachedTime) > maxAge;
    } catch (e) {
      return true; // Treat as stale if parsing fails
    }
  }

  Future<void> deleteExpiredCache({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now().subtract(maxAge).toIso8601String();
      await db.delete(
        'devices',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
      await db.delete(
        'sessions',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
      await db.delete(
        'events',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
      await db.delete(
        'summaries',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
    } catch (e) {
      // Delete error - silently continue
    }
  }
}
