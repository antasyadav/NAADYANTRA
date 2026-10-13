import '../models/session.dart';
import '../models/event.dart';
import '../models/common.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/storage/local_database.dart';

class SessionRepository {
  final ApiClient _apiClient;
  final LocalDatabase _cache;

  SessionRepository({ApiClient? apiClient, LocalDatabase? cache})
    : _apiClient = apiClient ?? ApiClient(),
      _cache = cache ?? LocalDatabase();

  Future<PaginatedResponse<Session>> getSessions({
    int page = 1,
    int pageSize = 50,
    String? deviceId,
    String? traineeId,
    String? status,
    bool useCache = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (traineeId != null) queryParams['trainee_id'] = traineeId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        ApiConstants.sessions,
        queryParameters: queryParams,
      );

      final paginatedResponse = PaginatedResponse<Session>.fromJson(
        response.data,
        (json) => Session.fromJson(json as Map<String, dynamic>),
      );

      // Cache successful responses
      for (final session in paginatedResponse.items) {
        await _cache.cacheSession(session.toJson());
      }

      return paginatedResponse;
    } on NetworkException {
      if (useCache) {
        final cachedSessions = await _cache.getCachedSessions(
          deviceId: deviceId,
          traineeId: traineeId,
          limit: pageSize,
        );
        if (cachedSessions.isNotEmpty) {
          return PaginatedResponse(
            total: cachedSessions.length,
            page: page,
            pageSize: pageSize,
            items: cachedSessions
                .map((json) => Session.fromJson(json))
                .toList(),
            isFromCache: true,
          );
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch sessions');
    }
  }

  Future<Session> getSession(
    int sessionId, {
    String? deviceId,
    bool useCache = true,
  }) async {
    try {
      final queryParams = deviceId != null ? {'device_id': deviceId} : null;
      final response = await _apiClient.get(
        ApiConstants.session(sessionId.toString()),
        queryParameters: queryParams,
      );
      final session = Session.fromJson(response.data);
      await _cache.cacheSession(session.toJson());
      return session;
    } on NetworkException {
      if (useCache) {
        final cachedSession = await _cache.getCachedSession(sessionId);
        if (cachedSession != null) {
          return Session.fromJson(cachedSession);
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch session');
    }
  }

  Future<PaginatedResponse<Event>> getSessionEvents(
    int sessionId, {
    String? deviceId,
    int page = 1,
    int pageSize = 100,
    String? event,
    String? cause,
    String? alert,
    bool useCache = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (event != null) queryParams['event'] = event;
      if (cause != null) queryParams['cause'] = cause;
      if (alert != null) queryParams['alert'] = alert;

      final response = await _apiClient.get(
        ApiConstants.sessionEvents(sessionId.toString()),
        queryParameters: queryParams,
      );

      final paginatedResponse = PaginatedResponse<Event>.fromJson(
        response.data,
        (json) => Event.fromJson(json as Map<String, dynamic>),
      );

      for (final eventData in paginatedResponse.items) {
        await _cache.cacheEvent(eventData.toJson());
      }

      return paginatedResponse;
    } on NetworkException {
      if (useCache) {
        final cachedEvents = await _cache.getCachedEvents(sessionId);
        if (cachedEvents.isNotEmpty) {
          return PaginatedResponse(
            total: cachedEvents.length,
            page: page,
            pageSize: pageSize,
            items: cachedEvents.map((json) => Event.fromJson(json)).toList(),
          );
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch session events');
    }
  }

  Future<SessionSummary> getSessionSummary(
    int sessionId, {
    String? deviceId,
    bool useCache = true,
  }) async {
    try {
      final queryParams = deviceId != null ? {'device_id': deviceId} : null;
      final response = await _apiClient.get(
        ApiConstants.sessionSummary(sessionId.toString()),
        queryParameters: queryParams,
      );
      final summary = SessionSummary.fromJson(response.data);
      await _cache.cacheSummary(summary.toJson());
      return summary;
    } on NetworkException {
      if (useCache) {
        final cachedSummary = await _cache.getCachedSummary(sessionId);
        if (cachedSummary != null) {
          return SessionSummary.fromJson(cachedSummary);
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch session summary');
    }
  }
}
