import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../shared/models/session.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/common.dart';
import '../../../shared/services/providers.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(widget.sessionId));
    final summaryAsync = ref.watch(sessionSummaryProvider(widget.sessionId));
    final eventsAsync = ref.watch(sessionEventsProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Session #${widget.sessionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportSession(context),
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSessionHeader(context, session)),
              SliverToBoxAdapter(
                child: _buildSummarySection(context, summaryAsync),
              ),
              SliverToBoxAdapter(
                child: _buildEventsSection(context, eventsAsync),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context, Session session) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: session.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: session.isActive ? Colors.green : Colors.blue,
                    ),
                  ),
                  child: Text(
                    session.isActive ? 'Active' : 'Completed',
                    style: TextStyle(
                      color: session.isActive ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Session #${session.sessionId}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Device', session.deviceId),
            _buildInfoRow(context, 'Trainee', session.traineeId),
            _buildInfoRow(
              context,
              'Started',
              DateFormat('MMM d, yyyy HH:mm:ss').format(session.startedAt),
            ),
            if (session.endedAt != null)
              _buildInfoRow(
                context,
                'Ended',
                DateFormat('MMM d, yyyy HH:mm:ss').format(session.endedAt!),
              ),
            if (session.endedAt != null)
              _buildInfoRow(
                context,
                'Duration',
                _formatDuration(session.duration),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    AsyncValue<SessionSummary> summaryAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Session Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              summaryAsync.when(
                data: (summary) {
                  return Column(
                    children: [
                      _buildSummaryRow(
                        context,
                        'Duration',
                        '${summary.durationSeconds}s',
                      ),
                      _buildSummaryRow(
                        context,
                        'Windows',
                        '${summary.windows}',
                      ),
                      _buildSummaryRow(
                        context,
                        'Leak Events',
                        '${summary.leakEvents}',
                      ),
                      _buildSummaryRow(
                        context,
                        'Gas Events',
                        '${summary.gasEvents}',
                      ),
                      _buildSummaryRow(
                        context,
                        'Moisture Events',
                        '${summary.wetEvents}',
                      ),
                      _buildSummaryRow(
                        context,
                        'Noise Windows',
                        '${summary.noiseWindows}',
                      ),
                      if (summary.maxLeakProbability != null)
                        _buildSummaryRow(
                          context,
                          'Max Leak Probability',
                          '${(summary.maxLeakProbability! * 100).toStringAsFixed(1)}%',
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Text(
                  'Summary not available',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsSection(
    BuildContext context,
    AsyncValue<PaginatedResponse<Event>> eventsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
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
                    'Event Timeline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              eventsAsync.when(
                data: (paginatedResponse) {
                  if (paginatedResponse.items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No events recorded',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: paginatedResponse.items.map((event) {
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
                error: (error, stack) => Text(
                  'Failed to load events',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
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
            width: 80,
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

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Session',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, HH:mm:ss').format(dateTime);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
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

  Future<void> _exportSession(BuildContext context) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/api/v1/sessions/${widget.sessionId}/export',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(
          directory.path,
          'session_${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.csv',
        );

        final file = await File(filePath).writeAsBytes(response.data);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV exported to ${file.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // In a real app, you would use a file viewer or share intent
                },
              ),
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshData() {
    ref.invalidate(sessionProvider(widget.sessionId));
    ref.invalidate(sessionSummaryProvider(widget.sessionId));
    ref.invalidate(sessionEventsProvider(widget.sessionId));
  }
}

// Providers for session detail
final sessionProvider = FutureProvider.family<Session, int>((
  ref,
  sessionId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return await sessionRepo.getSession(sessionId);
});

final sessionSummaryProvider = FutureProvider.family<SessionSummary, int>((
  ref,
  sessionId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return await sessionRepo.getSessionSummary(sessionId);
});

final sessionEventsProvider =
    FutureProvider.family<PaginatedResponse<Event>, int>((
      ref,
      sessionId,
    ) async {
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      return await sessionRepo.getSessionEvents(
        sessionId,
        page: 1,
        pageSize: 100,
      );
    });
