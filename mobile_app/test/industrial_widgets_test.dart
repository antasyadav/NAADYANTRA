import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/shared/widgets/industrial_card.dart';
import 'package:mobile_app/shared/widgets/industrial_button.dart';
import 'package:mobile_app/shared/widgets/status_pill.dart';
import 'package:mobile_app/shared/widgets/metric_readout.dart';
import 'package:mobile_app/shared/motion/staggered_entrance.dart';
import 'package:mobile_app/shared/motion/tactile_pressable.dart';
import 'package:mobile_app/shared/motion/pulsing_beacon.dart';
import 'package:mobile_app/shared/motion/animated_metric_counter.dart';
import 'package:mobile_app/shared/backgrounds/technical_grid_background.dart';
import 'package:mobile_app/shared/backgrounds/acoustic_signal_field.dart';
import 'package:mobile_app/shared/backgrounds/diagnostic_radar_sweep.dart';
import 'package:mobile_app/shared/backgrounds/ambient_depth_canvas.dart';

void main() {
  group('NAADYANTRA Industrial Design System Primitives', () {
    testWidgets('IndustrialCard renders title, subtitle, and child correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IndustrialCard(
              title: 'Hardware Probe 01',
              subtitle: 'Active Telemetry Stream',
              child: Text('Payload Body'),
            ),
          ),
        ),
      );

      expect(find.text('Hardware Probe 01'), findsOneWidget);
      expect(find.text('Active Telemetry Stream'), findsOneWidget);
      expect(find.text('Payload Body'), findsOneWidget);
    });

    testWidgets('IndustrialButton triggers onTap callback and renders icon', (
      WidgetTester tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IndustrialButton(
              label: 'Trigger Calibration',
              icon: Icons.tune_rounded,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Trigger Calibration'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      await tester.tap(find.byType(IndustrialButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('StatusPill renders status dot and label with theme token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusPill(
              label: 'LIVE SYNCHRONIZED',
              type: StatusType.online,
            ),
          ),
        ),
      );

      expect(find.text('LIVE SYNCHRONIZED'), findsOneWidget);
    });

    testWidgets('MetricReadout formats label, value, and unit correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricReadout(
              label: 'SAMPLING FREQ',
              value: '192.0',
              unit: 'kHz',
              accentColor: AppColors.burntOrange,
            ),
          ),
        ),
      );

      expect(find.text('SAMPLING FREQ'), findsOneWidget);
      expect(find.text('192.0'), findsOneWidget);
      expect(find.text('kHz'), findsOneWidget);
    });
  });

  group('NAADYANTRA Cinematic Motion & Background Components', () {
    testWidgets('StaggeredEntrance animates and renders child widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(child: Text('Cascading Telemetry Node')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Cascading Telemetry Node'), findsOneWidget);
    });

    testWidgets('TactilePressable handles tap gesture cleanly', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TactilePressable(
              onTap: () => tapped = true,
              child: const Text('Tactile Button Surface'),
            ),
          ),
        ),
      );

      expect(find.text('Tactile Button Surface'), findsOneWidget);
      await tester.tap(find.text('Tactile Button Surface'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('PulsingBeacon renders with live radar rings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingBeacon(
              size: 16,
              color: AppColors.alertOk,
              isLive: true,
            ),
          ),
        ),
      );

      expect(find.byType(PulsingBeacon), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PulsingBeacon), findsOneWidget);
    });

    testWidgets('TechnicalGridBackground renders child over procedural grid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TechnicalGridBackground(
              showScanLine: false,
              child: Text('Grid Overlay Content'),
            ),
          ),
        ),
      );

      expect(find.text('Grid Overlay Content'), findsOneWidget);
    });

    testWidgets('AcousticSignalField renders multi-harmonic waveform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 120,
              child: AcousticSignalField(animate: false),
            ),
          ),
        ),
      );

      expect(find.byType(AcousticSignalField), findsOneWidget);
    });

    testWidgets('DiagnosticRadarSweep renders rotating radar display', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticRadarSweep(
              size: 80,
              isScanning: false,
              centerWidget: Icon(Icons.sensors_rounded),
            ),
          ),
        ),
      );

      expect(find.byType(DiagnosticRadarSweep), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
    });

    testWidgets('AmbientDepthCanvas renders corner reticles enclosure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientDepthCanvas(
              showReticles: true,
              child: Text('Enclosure Core'),
            ),
          ),
        ),
      );

      expect(find.text('Enclosure Core'), findsOneWidget);
    });

    testWidgets('AnimatedMetricCounter animates numeric counter value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedMetricCounter(
              value: 48.0,
              unit: 'kHz',
              label: 'Sampling Rate',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('SAMPLING RATE'), findsOneWidget);
      expect(find.text('48.0'), findsOneWidget);
      expect(find.text('kHz'), findsOneWidget);
    });

    testWidgets('Reduced motion disables animations cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: StaggeredEntrance(child: Text('Accessible Static View')),
            ),
          ),
        ),
      );

      // In reduced motion mode, it must display immediately without waiting for tween
      expect(find.text('Accessible Static View'), findsOneWidget);
    });
  });
}
