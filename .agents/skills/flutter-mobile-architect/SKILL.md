---
name: flutter-mobile-architect
description: >-
  Lead mobile architect for Flutter, Dart, Riverpod, GoRouter, Dio, SQLite offline caching,
  CustomPainter, native animations, and Android build stability.
---

# Flutter Mobile Architect Skill

## Procedures
1. **State Isolation**:
   - Keep business logic in `Notifier` or `AsyncNotifier` classes.
   - Use `ref.watch()` for reactive UI triggers and `ref.read()` inside user interaction callbacks.
2. **Offline-First Persistence**:
   - Route network data through the SQLite caching layer (`sqflite`) so the app functions seamlessly in disconnected industrial environments.
3. **Canvas & Animation Hygiene**:
   ```dart
   class WaveformPainter extends CustomPainter {
     final List<double> samples;
     WaveformPainter(this.samples);

     @override
     void paint(Canvas canvas, Size size) {
       // paint acoustic waveforms cleanly
     }

     @override
     bool shouldRepaint(covariant WaveformPainter oldDelegate) {
       return oldDelegate.samples != samples;
     }
   }
   ```
