import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/services/providers.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/devices/screens/device_details_screen.dart';
import '../features/sessions/screens/session_list_screen.dart';
import '../features/sessions/screens/session_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (!authState.isAuthenticated && state.uri.toString() != '/login') {
        return '/login';
      }
      if (authState.isAuthenticated && state.uri.toString() == '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/devices/:deviceId',
        name: 'device-details',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return DeviceDetailsScreen(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/sessions',
        name: 'sessions',
        builder: (context, state) => const SessionListScreen(),
      ),
      GoRoute(
        path: '/sessions/:sessionId',
        name: 'session-detail',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return SessionDetailScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
