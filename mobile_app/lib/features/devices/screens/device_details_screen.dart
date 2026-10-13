import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/device.dart';
import '../../../shared/services/providers.dart';
import '../../../shared/widgets/industrial_card.dart';
import '../../../shared/widgets/industrial_button.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/metric_readout.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/motion/staggered_entrance.dart';
import '../../../shared/motion/pulsing_beacon.dart';
import '../../../shared/backgrounds/diagnostic_radar_sweep.dart';
import '../../../shared/backgrounds/ambient_depth_canvas.dart';
import '../../../shared/backgrounds/animated_screen_background.dart';

final singleDeviceStatusProvider =
    FutureProvider.family<DeviceStatus, String>((ref, deviceId) async {
      final repo = ref.watch(deviceRepositoryProvider);
      return await repo.getDeviceStatus(deviceId);
    });

final singleDeviceDetailsProvider = FutureProvider.family<Device, String>((
  ref,
  deviceId,
) async {
  final repo = ref.watch(deviceRepositoryProvider);
  return await repo.getDevice(deviceId);
});

class DeviceDetailsScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(singleDeviceStatusProvider(deviceId));
    final deviceAsync = ref.watch(singleDeviceDetailsProvider(deviceId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('NODE: $deviceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Ping Node',
            onPressed: () {
              ref.invalidate(singleDeviceStatusProvider(deviceId));
              ref.invalidate(singleDeviceDetailsProvider(deviceId));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statusAsync.when(
        data: (status) {
          final isOnline = status.isOnline;

          return AnimatedScreenBackground(
            theme: ScreenBackgroundTheme.circuitTrace,
            intensity: 0.8,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Main Hardware Status Card with Diagnostic Radar Sweep
              StaggeredEntrance(
                index: 0,
                child: IndustrialCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              DiagnosticRadarSweep(
                                size: 58,
                                isScanning: isOnline,
                              ),
                              Icon(
                                isOnline
                                    ? Icons.sensors_rounded
                                    : Icons.sensors_off_rounded,
                                color: isOnline
                                    ? AppColors.burntOrange
                                    : AppColors.warmGraphite,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      status.deviceId,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isOnline) ...[
                                      const PulsingBeacon(
                                        size: 8,
                                        color: AppColors.alertOk,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    StatusPill(
                                      label: isOnline ? 'ONLINE' : 'OFFLINE',
                                      type: isOnline
                                          ? StatusType.online
                                          : StatusType.offline,
                                      showDot: !isOnline,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.firmwareVersion != null
                                      ? 'Firmware: ${status.firmwareVersion}'
                                      : 'Firmware: ESP32-v1.4.2-prod',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warmGraphite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.warmStone,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LAST TELEMETRY SYNC',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.warmGraphite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.lastSeenAt != null
                                    ? DateFormat(
                                        'yyyy-MM-dd HH:mm:ss',
                                      ).format(status.lastSeenAt!)
                                    : 'Active recently',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          IndustrialButton(
                            label: 'Set as Active',
                            height: 36,
                            variant: IndustrialButtonVariant.secondary,
                            onPressed: () {
                              ref.read(selectedDeviceIdProvider.notifier).state =
                                  deviceId;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Node $deviceId selected as active probe.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Metrics Row
              StaggeredEntrance(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: MetricReadout(
                        label: '24h Activity',
                        value: '${status.recentActivityCount}',
                        unit: 'bursts',
                        icon: Icons.graphic_eq_rounded,
                        accentColor: AppColors.burntOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: MetricReadout(
                        label: 'Sampling',
                        value: '48.0',
                        unit: 'kHz',
                        icon: Icons.speed_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: MetricReadout(
                        label: 'ADC Width',
                        value: '12',
                        unit: 'bits',
                        icon: Icons.tune_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Active Error / Diagnostic Alerts Card
              if (status.lastError != null) ...[
                StaggeredEntrance(
                  index: 2,
                  child: IndustrialCard(
                    borderColor: AppColors.alertDanger,
                    backgroundColor: AppColors.alertDanger.withValues(
                      alpha: 0.06,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: AppColors.alertDanger,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Telemetry Anomaly Detected',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.alertDanger,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status.lastError!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Hardware Specifications Breakdown
              StaggeredEntrance(
                index: 3,
                child: AmbientDepthCanvas(
                  showReticles: true,
                  child: IndustrialCard(
                    title: 'Hardware & Bus Architecture',
                    subtitle: 'Physical Sensor Bus Configuration',
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'MCU Core',
                          'ESP32-S3 Dual-Core LX7 @ 240 MHz',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Acoustic Sampling Bus',
                          'I2S Master Direct DMA Channel',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Sampling Window',
                          '4096 Samples / 85.3 ms Buffer',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Telemetry Protocol',
                          'FastAPI WebSocket + REST Fallback',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Device Metadata
              deviceAsync.when(
                data: (device) => StaggeredEntrance(
                  index: 4,
                  child: IndustrialCard(
                    title: 'Node Metadata',
                    subtitle: 'Device Registration Registry',
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Hardware Label',
                          device.name ?? 'Acoustic Diagnostic Rig',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Deployment Area',
                          (device.deviceMetadata['location'] as String?) ??
                              'Sector 4 Inspection Bench',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Registration Status',
                          device.isActive
                              ? 'Active Telemetry Link'
                              : 'Standby Node',
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Action Bar
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 5,
                child: IndustrialButton(
                  label: 'Launch Inspection Feed on this Node',
                  icon: Icons.radar_rounded,
                  onPressed: () {
                    ref.read(selectedDeviceIdProvider.notifier).state =
                        deviceId;
                    context.go('/');
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            ),
          );
        },
        loading: () => const IndustrialLoadingView(
          message: 'Pinging Hardware Telemetry Bus...',
        ),
        error: (err, _) => IndustrialErrorView(
          message: 'Failed to communicate with Node $deviceId: $err',
          onRetry: () {
            ref.invalidate(singleDeviceStatusProvider(deviceId));
            ref.invalidate(singleDeviceDetailsProvider(deviceId));
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmGraphite,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
