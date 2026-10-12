import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/device.dart';
import '../../../shared/models/event.dart';
import '../../../shared/services/providers.dart';
import '../../../core/config/app_config.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key});

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    if (!_isPolling) {
      _isPolling = true;
      _pollingTimer = Timer.periodic(
        AppConfig.liveInspectionPollInterval,
        (_) => _refreshData(),
      );
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _refreshData() async {
    if (mounted) {
      ref.invalidate(deviceStatusProvider);
      ref.invalidate(recentEventsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceStatus = ref.watch(deviceStatusProvider);
    final recentEvents = ref.watch(recentEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Inspection'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Device Status Card
            deviceStatus.when(
              data: (status) => _buildDeviceStatusCard(context, status),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Failed to load device status'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            _buildInstructionsCard(context),
            const SizedBox(height: 16),

            // Recent Events
            _buildRecentEventsCard(context, recentEvents),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard(
    BuildContext context,
    DeviceStatus deviceStatus,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  deviceStatus.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: deviceStatus.isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  deviceStatus.deviceId,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deviceStatus.isOnline
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: deviceStatus.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    deviceStatus.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: deviceStatus.isOnline ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (deviceStatus.lastSeenAt != null) ...[
              _buildInfoRow(
                context,
                'Last Seen',
                _formatDateTime(deviceStatus.lastSeenAt!),
              ),
            ],
            if (deviceStatus.firmwareVersion != null) ...[
              _buildInfoRow(context, 'Firmware', deviceStatus.firmwareVersion!),
            ],
            _buildInfoRow(
              context,
              'Recent Activity',
              '${deviceStatus.recentActivityCount} events (24h)',
            ),
            if (deviceStatus.lastError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deviceStatus.lastError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Session Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The ESP32 device controls sessions using its physical BOOT button:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '1',
              'Press BOOT button briefly to START a session',
            ),
            _buildInstructionStep(
              '2',
              'Perform inspection in controlled environment',
            ),
            _buildInstructionStep(
              '3',
              'Press BOOT button again to STOP the session',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This is a training aid only. Not a certified safety instrument.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard(
    BuildContext context,
    AsyncValue<List<Event>> recentEvents,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Recent Events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentEvents.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No recent events',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start a session on the device to see events here',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: events.take(10).map((event) {
                    return _buildEventTile(context, event);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load events',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    final alertColor = _getAlertColor(event.alert);

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(event.eventName),
              color: alertColor,
              size: 20,
            ),
          ),
          title: Text(
            event.eventName ?? event.eventKind,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDateTime(event.serverTimestamp)),
              if (event.alert != null)
                Text(
                  event.alert!,
                  style: TextStyle(color: alertColor, fontSize: 12),
                ),
              if (event.cause != null)
                Text(
                  event.cause!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: _buildSensorChip(event),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSensorChip(Event event) {
    final sensors = <String>[];
    if (event.hasGasData) sensors.add('Gas');
    if (event.hasAcousticData) sensors.add('Acoustic');
    if (event.hasMoistureData) sensors.add('Moisture');
    if (event.hasTemperatureData) sensors.add('Temp');
    if (event.hasUvData) sensors.add('UV');

    if (sensors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        sensors.join(', '),
        style: const TextStyle(fontSize: 10, color: Colors.blue),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  Color _getAlertColor(String? alert) {
    switch (alert) {
      case 'DANGER':
        return Colors.red;
      case 'CAUTION':
        return Colors.orange;
      case 'OK':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String? eventName) {
    switch (eventName) {
      case 'session_start':
        return Icons.play_circle;
      case 'session_stop':
        return Icons.stop_circle;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.sensors;
    }
  }
}

// Providers for inspection screen
final deviceStatusProvider = FutureProvider<DeviceStatus>((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final selectedDeviceId = ref.watch(selectedDeviceIdProvider);
  // Use selected device ID or default
  final deviceId = selectedDeviceId ?? 'SIH-DEV-01';
  return await deviceRepo.getDeviceStatus(deviceId);
});

final recentEventsProvider = FutureProvider<List<Event>>((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final selectedDeviceId = ref.watch(selectedDeviceIdProvider);
  // Get most recent session's events
  final sessions = await sessionRepo.getSessions(
    page: 1,
    pageSize: 1,
    deviceId: selectedDeviceId,
  );
  if (sessions.items.isEmpty) return [];

  final events = await sessionRepo.getSessionEvents(
    sessions.items.first.id,
    page: 1,
    pageSize: 10,
  );
  return events.items;
});
