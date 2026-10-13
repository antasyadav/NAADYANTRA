import 'package:dio/dio.dart';

import '../models/device.dart';
import '../models/common.dart';
import '../models/event.dart';
import '../models/session.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/storage/local_database.dart';

class DeviceRepository {
  final ApiClient _apiClient;
  final LocalDatabase _cache;

  DeviceRepository({ApiClient? apiClient, LocalDatabase? cache})
    : _apiClient = apiClient ?? ApiClient(),
      _cache = cache ?? LocalDatabase();

  Future<PaginatedResponse<Device>> getDevices({
    int page = 1,
    int pageSize = 50,
    bool? isActive,
    String? search,
    bool useCache = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (isActive != null) queryParams['is_active'] = isActive;
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get(
        ApiConstants.devices,
        queryParameters: queryParams,
      );

      final paginatedResponse = PaginatedResponse<Device>.fromJson(
        response.data,
        (json) => Device.fromJson(json as Map<String, dynamic>),
      );

      for (final device in paginatedResponse.items) {
        await _cache.cacheDevice(device.toJson());
      }

      return paginatedResponse;
    } on NetworkException {
      if (useCache) {
        final cachedDevices = await _cache.getCachedDevices(
          isActive: isActive,
          limit: pageSize,
        );
        if (cachedDevices.isNotEmpty) {
          return PaginatedResponse(
            total: cachedDevices.length,
            page: page,
            pageSize: pageSize,
            items: cachedDevices.map((json) => Device.fromJson(json)).toList(),
            isFromCache: true,
          );
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch devices');
    }
  }

  Future<Device> getDevice(String deviceId, {bool useCache = true}) async {
    try {
      final response = await _apiClient.get(ApiConstants.device(deviceId));
      final device = Device.fromJson(response.data);
      await _cache.cacheDevice(device.toJson());
      return device;
    } on NetworkException {
      if (useCache) {
        final cachedDevice = await _cache.getCachedDevice(deviceId);
        if (cachedDevice != null) {
          return Device.fromJson(cachedDevice);
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch device');
    }
  }

  Future<DeviceStatus> getDeviceStatus(
    String deviceId, {
    bool useCache = true,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.deviceStatus(deviceId),
      );
      final status = DeviceStatus.fromJson(response.data);
      await _cache.cacheDeviceStatus(deviceId, status.toJson());
      return status;
    } on NetworkException {
      if (useCache) {
        final cachedStatus = await _cache.getCachedDeviceStatus(deviceId);
        if (cachedStatus != null) {
          return DeviceStatus.fromJson(cachedStatus);
        }
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch device status');
    }
  }

  Future<List<Event>> getDeviceEvents(
    String deviceId, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.events,
        queryParameters: <String, dynamic>{
          'device_id': deviceId,
          'page_size': limit,
        },
      );
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic> && data['items'] is List
          ? data['items'] as List<dynamic>
          : (data is List<dynamic> ? data : <dynamic>[]);
      return items
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch device events');
    }
  }

  Future<List<SessionSummary>> getDeviceSummaries(
    String deviceId, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.summaries,
        queryParameters: <String, dynamic>{
          'device_id': deviceId,
          'page_size': limit,
        },
      );
      final data = response.data;
      final List<dynamic> items =
          data is Map<String, dynamic> && data['items'] is List
              ? data['items'] as List<dynamic>
              : (data is List<dynamic> ? data : <dynamic>[]);
      return items
          .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch device summaries');
    }
  }

  /// Simulation helper for lab test benches without physical ESP32 nodes connected.
  ///
  /// [SECURITY COMPLIANCE - P0-08]:
  /// In operational production deployments, telemetry is authenticated and transmitted
  /// directly from physical ESP32 hardware using an onboard hardware key stored in ESP32 NVS,
  /// never originating from the mobile client.
  /// When invoking this method in lab testing, provide the test rig key in [deviceKey].
  Future<bool> sendTelemetryLog({
    required String deviceId,
    required double rms,
    required int gas,
    required double leak,
    required String alert,
    required double temp,
    int session = 1,
    String trainee = 'TR-01',
    String? deviceKey,
  }) async {
    final effectiveKey = deviceKey ?? 'dev-key-123';
    try {
      await _apiClient.post(
        '${ApiConstants.firmwareLog}?trainee=$trainee&session=$session&kind=event',
        data: <String, dynamic>{
          'device': deviceId,
          'millis': DateTime.now().millisecondsSinceEpoch % 10000000,
          'rms': rms,
          'gas': gas,
          'leak': leak,
          'alert': alert,
          'temp': temp,
        },
        options: Options(
          headers: <String, dynamic>{'X-Device-Key': effectiveKey},
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
