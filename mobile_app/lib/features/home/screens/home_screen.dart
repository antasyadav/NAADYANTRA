import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/providers.dart';
import '../../../shared/widgets/industrial_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/metric_readout.dart';
import '../../../shared/motion/staggered_entrance.dart';
import '../../../shared/motion/pulsing_beacon.dart';
import '../../../shared/motion/tactile_pressable.dart';
import '../../../shared/backgrounds/animated_screen_background.dart';
import '../../settings/screens/settings_screen.dart';
import '../../inspection/screens/inspection_screen.dart';
import '../../sessions/screens/session_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(onSwitchTab: _onDestinationSelected),
      const _InspectTab(),
      const _HistoryTab(),
      const _SettingsTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors_rounded),
            label: 'Live Inspect',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Home Tab (Overview)
class _HomeTab extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;

  const _HomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDeviceId =
        ref.watch(selectedDeviceIdProvider) ?? 'SIH-DEV-01';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightBurntOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sensors_rounded,
                size: 20,
                color: AppColors.burntOrange,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NAADYANTRA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'DIAGNOSTIC WORKSTATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.warmGraphite,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedScreenBackground(
        theme: ScreenBackgroundTheme.overview,
        intensity: 0.85,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
              // Greeting Banner Card
              StaggeredEntrance(
                index: 0,
                child: IndustrialCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.pureWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.warmStone,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (authState.username ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.burntOrange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Welcome, ${authState.username ?? "Operator"}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const StatusPill(
                                  label: 'CERTIFIED',
                                  type: StatusType.completed,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Acoustic Pipeline & Valve Inspection Aid',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Primary Device Status Monitor Card
              StaggeredEntrance(
                index: 1,
                child: IndustrialCard(
                  title: 'Active Hardware Node',
                  subtitle: 'Target Diagnostic Telemetry Probe',
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulsingBeacon(size: 9, color: AppColors.alertOk),
                      SizedBox(width: 6),
                      StatusPill(
                        label: 'ONLINE',
                        type: StatusType.online,
                        showDot: false,
                      ),
                    ],
                  ),
                  onTap: () => context.go('/devices/$selectedDeviceId'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightBurntOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.memory_rounded,
                              color: AppColors.burntOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedDeviceId,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'ESP32-S3 Acoustic Rig • 48 kHz Sampling',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warmGraphite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.warmGraphite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.industrialIvory,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Signal Quality: Nominal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Tap to inspect node →',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.burntOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Telemetry Statistics (3-Column Layout)
              StaggeredEntrance(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        'TELEMETRY METRICS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.warmGraphite,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: MetricReadout(
                            label: 'Sessions',
                            value: '12',
                            unit: 'runs',
                            icon: Icons.assignment_outlined,
                            onTap: () => onSwitchTab(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MetricReadout(
                            label: 'Nodes',
                            value: '3',
                            unit: 'paired',
                            icon: Icons.devices_outlined,
                            onTap: () =>
                                context.go('/devices/$selectedDeviceId'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MetricReadout(
                            label: 'Events',
                            value: '24',
                            unit: 'logged',
                            icon: Icons.timeline_outlined,
                            onTap: () => onSwitchTab(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Workflow Actions with Tactile Feedback
              StaggeredEntrance(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'WORKFLOW ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.warmGraphite,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TactilePressable(
                            onTap: () => onSwitchTab(1),
                            child: IndustrialCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.burntOrange.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.radar_rounded,
                                      color: AppColors.burntOrange,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Live Inspection',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Stream Real-Time FFT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warmGraphite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TactilePressable(
                            onTap: () => onSwitchTab(2),
                            child: IndustrialCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceElevated
                                          : AppColors.softSand.withValues(
                                              alpha: 0.4,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.history_edu_rounded,
                                      color: AppColors.darkBurntOrange,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Session Archive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Audit Past Diagnostics',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warmGraphite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TactilePressable(
                      onTap: () => context.push('/assessments'),
                      child: IndustrialCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.burntOrange.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: AppColors.burntOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vocational Skill Evaluations',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'SIH26244 Rubrics • Trainee Competency Scorecard',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warmGraphite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.warmGraphite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Recent Activity Log Card
              StaggeredEntrance(
                index: 4,
                child: IndustrialCard(
                  title: 'Recent Diagnostic Events',
                  subtitle: 'Last Recorded Telemetry Bursts',
                  trailing: TextButton(
                    onPressed: () => onSwitchTab(2),
                    child: const Text('View All'),
                  ),
                  child: Column(
                    children: [
                      _buildActivityTile(
                        context,
                        icon: Icons.play_circle_outline_rounded,
                        iconColor: AppColors.alertOk,
                        title: 'Diagnostic Session #104 Completed',
                        time: '2 hours ago • Pipe Line A-4',
                        status: 'OK',
                        statusType: StatusType.ok,
                      ),
                      const Divider(),
                      _buildActivityTile(
                        context,
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.alertCaution,
                        title: 'Acoustic Anomaly Flagged',
                        time: '5 hours ago • Valve V-02',
                        status: 'CAUTION',
                        statusType: StatusType.caution,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildActivityTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String status,
    required StatusType statusType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warmGraphite,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(label: status, type: statusType),
        ],
      ),
    );
  }
}

// Inspect Tab Placeholder wrapper
class _InspectTab extends StatelessWidget {
  const _InspectTab();

  @override
  Widget build(BuildContext context) {
    return const InspectionScreen();
  }
}

// History Tab Placeholder wrapper
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const SessionListScreen();
  }
}

// Settings Tab Placeholder wrapper
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
