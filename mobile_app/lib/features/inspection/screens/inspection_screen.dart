import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/device.dart';
import '../../../shared/models/event.dart';
import '../../../shared/services/providers.dart';
import '../../../shared/widgets/industrial_card.dart';
import '../../../shared/widgets/industrial_button.dart';
import '../../../shared/widgets/metric_readout.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/motion/staggered_entrance.dart';
import '../../../shared/motion/pulsing_beacon.dart';
import '../../../shared/motion/animated_fft_spectrum.dart';
import '../../../shared/backgrounds/diagnostic_radar_sweep.dart';
import '../../../shared/backgrounds/acoustic_signal_field.dart';
import '../../../shared/backgrounds/animated_screen_background.dart';

final deviceStatusProvider =
    FutureProvider.autoDispose<DeviceStatus>((ref) async {
      final deviceId = ref.watch(selectedDeviceIdProvider) ?? 'SIH-DEV-01';
      final repo = ref.watch(deviceRepositoryProvider);
      return await repo.getDeviceStatus(deviceId);
    });

final recentEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
      final deviceId = ref.watch(selectedDeviceIdProvider) ?? 'SIH-DEV-01';
      final repo = ref.watch(deviceRepositoryProvider);
      return await repo.getDeviceEvents(deviceId, limit: 10);
    });

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

  bool _isSimulating = false;

  Future<void> _simulateTelemetry({required bool isLeak}) async {
    if (_isSimulating) return;
    setState(() => _isSimulating = true);

    final deviceId = ref.read(selectedDeviceIdProvider) ?? 'SIH-DEV-01';
    final repo = ref.read(deviceRepositoryProvider);

    final rms = isLeak ? 1860.0 : 310.0;
    final gas = isLeak ? 465 : 42;
    final leak = isLeak ? 0.92 : 0.04;
    final alert = isLeak ? 'CRITICAL' : 'OK';
    final temp = isLeak ? 36.8 : 27.2;

    final success = await repo.sendTelemetryLog(
      deviceId: deviceId,
      rms: rms,
      gas: gas,
      leak: leak,
      alert: alert,
      temp: temp,
    );

    if (mounted) {
      setState(() => _isSimulating = false);
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isLeak
                    ? '⚠️ Ultrasonic Leak Telemetry Synced to Cloud (RMS: 1860, Leak: 92%)'
                    : '✅ Nominal Acoustic Baseline Synced to Cloud (RMS: 310, Leak: 4%)')
                : 'Telemetry broadcast completed in offline buffer',
          ),
          backgroundColor:
              isLeak ? AppColors.darkBurntOrange : AppColors.carbon,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            PulsingBeacon(size: 8, color: AppColors.burntOrange),
            SizedBox(width: 8),
            Text('LIVE DIAGNOSTIC PROBE'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Probes',
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedScreenBackground(
        theme: ScreenBackgroundTheme.liveSonar,
        intensity: 0.75,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Live Status Banner
            StaggeredEntrance(
              index: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.warmStone,
                  ),
                ),
                child: Row(
                  children: [
                    const StatusPill(
                      label: 'LIVE STREAM',
                      type: StatusType.active,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Polling telemetry every ${AppConfig.liveInspectionPollInterval.inSeconds}s',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warmGraphite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.sensors_rounded,
                      size: 18,
                      color: AppColors.burntOrange,
                    ),
                  ],
                ),
              ),
            ),

            // Device Status Card with Diagnostic Radar Sweep
            deviceStatus.when(
              data: (status) => StaggeredEntrance(
                index: 1,
                child: _buildDeviceStatusCard(context, status, isDark),
              ),
              loading: () => const IndustrialCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => IndustrialCard(
                borderColor: AppColors.alertDanger,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.alertDanger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to reach telemetry probe: $error',
                        style: const TextStyle(
                          color: AppColors.alertDanger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _refreshData,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Live Waveform Stream Trace
            const StaggeredEntrance(
              index: 2,
              child: IndustrialCard(
                title: 'Acoustic Carrier Stream',
                subtitle: 'Real-Time Microphone DMA Buffer Activity',
                child: Column(
                  children: [
                    SizedBox(
                      height: 80,
                      child: AcousticSignalField(
                        height: 80,
                        opacity: 0.7,
                        animate: true,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DMA Window: 4096 Samples',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warmGraphite,
                          ),
                        ),
                        Text(
                          'Sampling Rate: 192.0 kHz',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.burntOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '16-BAND ULTRASONIC FFT SPECTRUM',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.warmGraphite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '28-38 kHz Leak Window',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burntOrange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    AnimatedFftSpectrum(height: 38),
                  ],
                ),
              ),
            ),
            // Multi-Hazard Real-Time Sensor Telemetry Matrix
            StaggeredEntrance(
              index: 3,
              child: _buildSensorMatrixCard(context, recentEvents, isDark),
            ),
            const SizedBox(height: 12),

            // Interactive Hardware Rig Simulator
            StaggeredEntrance(
              index: 4,
              child: _buildSimulatorCard(context, isDark),
            ),
            const SizedBox(height: 12),

            // Physical Hardware Inspection Protocol Guide
            StaggeredEntrance(
              index: 5,
              child: _buildInstructionsCard(context, isDark),
            ),
            const SizedBox(height: 12),

            // Recent Events Stream
            StaggeredEntrance(
              index: 6,
              child: _buildRecentEventsCard(context, recentEvents, isDark),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard(
    BuildContext context,
    DeviceStatus deviceStatus,
    bool isDark,
  ) {
    final isOnline = deviceStatus.isOnline;

    return IndustrialCard(
      title: 'Target Node: ${deviceStatus.deviceId}',
      subtitle: isOnline
          ? 'Receiving High-Frequency Acoustic Packets'
          : 'Probe Standby / Inactive',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline) ...[
            const PulsingBeacon(size: 8, color: AppColors.alertOk),
            const SizedBox(width: 6),
          ],
          StatusPill(
            label: isOnline ? 'ONLINE' : 'OFFLINE',
            type: isOnline ? StatusType.online : StatusType.offline,
            showDot: !isOnline,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  DiagnosticRadarSweep(size: 50, isScanning: isOnline),
                  Icon(
                    isOnline
                        ? Icons.wifi_tethering_rounded
                        : Icons.portable_wifi_off_rounded,
                    color: isOnline
                        ? AppColors.alertOk
                        : AppColors.warmGraphite,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceStatus.deviceId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? 'Acoustic RMS baseline established'
                          : 'Awaiting serial / wireless handshake',
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
          const SizedBox(height: 14),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.warmStone),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bursts: ${deviceStatus.recentActivityCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                deviceStatus.lastSeenAt != null
                    ? 'Sync: ${DateFormat("HH:mm:ss").format(deviceStatus.lastSeenAt!)}'
                    : 'Awaiting Ping',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warmGraphite,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context, bool isDark) {
    return IndustrialCard(
      title: 'Physical Hardware Inspection Guide',
      subtitle: 'Standard Operating Protocol on ESP32-S3 Rig',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionStep(
            '1',
            'Position Acoustic Contact Probe',
            'Clamp or hold the ultrasound transducer firmly against the suspect pipe valve or weld seam.',
          ),
          const Divider(),
          _buildInstructionStep(
            '2',
            'Trigger BOOT Button (GPIO 0)',
            'Press the onboard BOOT button for 1.5s to start session recording and capture FFT frames.',
          ),
          const Divider(),
          _buildInstructionStep(
            '3',
            'Inspect Spectrum in Real-Time',
            'Watch the live timeline below for anomaly triggers, RMS surge flags, and gas telemetry.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.burntOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warmGraphite,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard(
    BuildContext context,
    AsyncValue<List<Event>> recentEventsAsync,
    bool isDark,
  ) {
    return IndustrialCard(
      title: 'Live Anomaly Stream',
      subtitle: 'Triggered Event Log from Acoustic Sensors',
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 18),
        onPressed: _refreshData,
      ),
      child: recentEventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 32,
                      color: AppColors.alertOk,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No Live Anomalies Detected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'RMS level remains within baseline calibration thresholds.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warmGraphite,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.take(10).length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventTile(context, event, isDark);
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, _) => Text(
          'Failed to load events: $error',
          style: const TextStyle(color: AppColors.alertDanger, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event, bool isDark) {
    final alertColor = _getAlertColor(event.alert);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning_amber_rounded, color: alertColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (event.cause ?? 'ANOMALY').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm:ss').format(event.serverTimestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.warmGraphite,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'RMS: ${event.rms?.toStringAsFixed(1) ?? "0.0"} | Gas Delta: ${event.gasDelta ?? 0}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warmGraphite,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label: event.alert ?? 'NORMAL',
            type: _getStatusType(event.alert),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMatrixCard(
    BuildContext context,
    AsyncValue<List<Event>> recentEventsAsync,
    bool isDark,
  ) {
    final events = recentEventsAsync.valueOrNull;
    final latestEvent = events != null && events.isNotEmpty ? events.first : null;
    final rmsValue = latestEvent?.rms != null
        ? latestEvent!.rms!.toStringAsFixed(1)
        : '340.0';
    final gasValue = latestEvent?.gasDelta != null
        ? '+${latestEvent!.gasDelta}'
        : '+42';
    final tempValue = latestEvent?.temperature != null
        ? '${latestEvent!.temperature!.toStringAsFixed(1)}°C'
        : '27.4°C';
    final leakScore = latestEvent?.leakProbability != null
        ? (latestEvent!.leakProbability! * 100).toInt()
        : 6;
    final isCritical = leakScore > 60;

    return IndustrialCard(
      title: 'Multi-Sensor Hazard Matrix',
      subtitle: 'Ultrasonic Piezo • MQ Gas Delta • Thermal Transducer',
      trailing: StatusPill(
        label: isCritical ? 'ANOMALY DETECTED' : 'CALIBRATED',
        type: isCritical ? StatusType.danger : StatusType.ok,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MetricReadout(
                  label: 'Ultrasonic RMS',
                  value: rmsValue,
                  unit: 'ADC',
                  icon: Icons.graphic_eq_rounded,
                  accentColor: isCritical ? AppColors.darkBurntOrange : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricReadout(
                  label: 'Gas Delta',
                  value: gasValue,
                  unit: 'ADC',
                  icon: Icons.air_rounded,
                  accentColor: isCritical ? AppColors.burntOrange : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricReadout(
                  label: 'Probe Temp',
                  value: tempValue,
                  unit: '',
                  icon: Icons.thermostat_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.industrialIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCritical
                    ? AppColors.alertDanger.withValues(alpha: 0.4)
                    : (isDark ? AppColors.darkBorder : AppColors.warmStone),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_alt_rounded,
                      size: 16,
                      color: AppColors.burntOrange,
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'ONNX Model Leak Signature Score',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$leakScore%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isCritical
                            ? AppColors.alertDanger
                            : AppColors.alertOk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (leakScore / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.darkBorder
                        : AppColors.warmStone,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCritical ? AppColors.burntOrange : AppColors.alertOk,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isCritical
                      ? '⚠️ High acoustic resonance in 28-39 kHz window indicates active pipe orifice leak.'
                      : 'Acoustic background matches baseline laminar pipe flow profile.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isCritical
                        ? AppColors.darkBurntOrange
                        : AppColors.warmGraphite,
                    fontWeight: isCritical ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(BuildContext context, bool isDark) {
    return IndustrialCard(
      title: 'Interactive Hardware Rig Simulator',
      subtitle: 'Broadcast Simulated ESP32 Telemetry to Live Cloud',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demonstrate real-time acoustic ingestion, cloud processing, and warning triggers without physical ESP32 rig attached:',
            style: TextStyle(fontSize: 11.5, color: AppColors.warmGraphite),
          ),
          const SizedBox(height: 12),
          if (_isSimulating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Broadcasting Telemetry Frame to Cloud...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.burntOrange,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IndustrialButton(
                  label: 'Simulate Nominal Baseline',
                  icon: Icons.check_circle_outline_rounded,
                  variant: IndustrialButtonVariant.secondary,
                  onPressed: () => _simulateTelemetry(isLeak: false),
                ),
                const SizedBox(height: 8),
                IndustrialButton(
                  label: 'Trigger Ultrasonic Leak Burst',
                  icon: Icons.warning_amber_rounded,
                  onPressed: () => _simulateTelemetry(isLeak: true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getAlertColor(String? alert) {
    if (alert == null) return AppColors.warmGraphite;
    switch (alert.toUpperCase()) {
      case 'DANGER':
      case 'CRITICAL':
        return AppColors.alertDanger;
      case 'CAUTION':
      case 'WARNING':
        return AppColors.alertCaution;
      case 'OK':
      case 'NOMINAL':
        return AppColors.alertOk;
      default:
        return AppColors.warmGraphite;
    }
  }

  StatusType _getStatusType(String? alert) {
    if (alert == null) return StatusType.neutral;
    switch (alert.toUpperCase()) {
      case 'DANGER':
      case 'CRITICAL':
        return StatusType.danger;
      case 'CAUTION':
      case 'WARNING':
        return StatusType.caution;
      case 'OK':
      case 'NOMINAL':
        return StatusType.ok;
      default:
        return StatusType.neutral;
    }
  }
}
