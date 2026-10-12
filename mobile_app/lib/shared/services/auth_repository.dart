import '../models/auth.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AuthRepository({ApiClient? apiClient, SecureStorageService? secureStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _secureStorage = secureStorage ?? SecureStorageService();

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: LoginRequest(username: username, password: password),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      // Save token
      await _secureStorage.saveAuthToken(loginResponse.accessToken);
      await _secureStorage.saveUsername(username);

      return loginResponse;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Login failed');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      // Ignore logout errors, proceed with local cleanup
    } finally {
      await _secureStorage.clearAuthToken();
      await _secureStorage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    return await _secureStorage.isLoggedIn();
  }

  Future<String?> getUsername() async {
    return await _secureStorage.getUsername();
  }
}
