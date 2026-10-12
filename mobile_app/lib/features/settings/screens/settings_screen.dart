import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/providers.dart';
import '../../assessments/screens/assessment_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(
                      (authState.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.username ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trainer',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Sections
          _buildSection(
            context,
            title: 'Connection',
            items: [
              _SettingsItem(
                icon: Icons.wifi,
                title: 'API URL',
                subtitle: 'http://10.0.2.2:8000',
                onTap: () {
                  // Show API URL dialog
                },
              ),
              _SettingsItem(
                icon: Icons.devices,
                title: 'Device Selection',
                subtitle:
                    ref.watch(selectedDeviceIdProvider) ?? 'Select a device',
                onTap: () {
                  _showDeviceSelectionDialog(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: 'Preferences',
            items: [
              _SettingsItem(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // Show language selection
                },
              ),
              _SettingsItem(
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: 'System',
                onTap: () {
                  // Show theme selection
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: 'Data',
            items: [
              _SettingsItem(
                icon: Icons.delete_outline,
                title: 'Clear Cache',
                subtitle: 'Remove cached data',
                onTap: () {
                  _showClearCacheDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: 'Assessments',
            items: [
              _SettingsItem(
                icon: Icons.assignment,
                title: 'View Assessments',
                subtitle: 'Review your assessment history',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssessmentListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: 'About',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: '1.0.0',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with the app',
                onTap: () {
                  // Show help screen
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logout Button
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Safety Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This is a training aid, not a certified safety instrument.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: items
                .map(
                  (item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    subtitle: item.subtitle != null
                        ? Text(item.subtitle!)
                        : null,
                    trailing: item.onTap != null
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: item.onTap,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showDeviceSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final devicesAsync = ref.watch(devicesProvider);
              return devicesAsync.when(
                data: (paginatedResponse) {
                  if (paginatedResponse.items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No devices available'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: paginatedResponse.items.length,
                    itemBuilder: (context, index) {
                      final device = paginatedResponse.items[index];
                      final isSelected =
                          ref.watch(selectedDeviceIdProvider) ==
                          device.deviceId;
                      return ListTile(
                        title: Text(device.name ?? device.deviceId),
                        subtitle: Text(
                          device.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: device.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onTap: () {
                          ref.read(selectedDeviceIdProvider.notifier).state =
                              device.deviceId;
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load devices'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(devicesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear cache logic
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}
