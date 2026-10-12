import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'device_repository.dart';
import 'session_repository.dart';
import 'assessment_repository.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/local_database.dart';

// API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Secure Storage
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Local Database
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(localDatabaseProvider),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(localDatabaseProvider),
  );
});

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(apiClient: ref.watch(apiClientProvider));
});

// Selected Device ID
final selectedDeviceIdProvider = StateProvider<String?>((ref) {
  return null;
});

// Device List Provider
final devicesProvider = FutureProvider.autoDispose((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return await deviceRepo.getDevices();
});

// Auth State
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final username = await _authRepository.getUsername();
      state = AuthState.authenticated(username ?? 'User');
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthState.loading();
    try {
      await _authRepository.login(username, password);
      state = AuthState.authenticated(username);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _authRepository.logout();
      state = AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? username;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.username,
    required this.isLoading,
    this.error,
  });

  factory AuthState.initial() =>
      AuthState(isAuthenticated: false, isLoading: false);

  factory AuthState.authenticated(String username) =>
      AuthState(isAuthenticated: true, username: username, isLoading: false);

  factory AuthState.loading() =>
      AuthState(isAuthenticated: false, isLoading: true);

  factory AuthState.error(String error) =>
      AuthState(isAuthenticated: false, isLoading: false, error: error);
}
