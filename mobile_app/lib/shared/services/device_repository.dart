import '../models/device.dart';
import '../models/common.dart';
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
}
