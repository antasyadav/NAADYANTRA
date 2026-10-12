import 'package:flutter/material.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device: $deviceId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(deviceId, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Device details coming soon'),
          ],
        ),
      ),
    );
  }
}
