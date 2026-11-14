import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/services/perf_telemetry_models.dart';
import 'package:nutrilens_provider/widgets/perf_debug_overlay.dart';

import '../fakes/fake_perf_telemetry_service.dart';

PortfolioPerfSnapshot _sampleSnapshot({
  double? totalReadyMs,
  double? assetsAndFontsMs = 95.0,
}) {
  return PortfolioPerfSnapshot(
    version: 1,
    renderer: 'skwasm',
    readySource: 'flutter',
    htmlFirstPaintMs: 24.0,
    engineLoadMs: 210.0,
    dartBootMs: 42.0,
    assetsAndFontsMs: assetsAndFontsMs,
    totalReadyMs: totalReadyMs,
    transferSizeKb: 1180.0,
    decodedBodySizeKb: 2600.0,
    byType: const {
      'wasm': PerfResourceBucket(
        transferSizeKb: 720.0,
        decodedBodySizeKb: 1710.0,
        count: 2,
        cachedCount: 0,
        opaqueCount: 0,
      ),
      'js': PerfResourceBucket(
        transferSizeKb: 220.0,
        decodedBodySizeKb: 600.0,
        count: 3,
        cachedCount: 0,
        opaqueCount: 0,
      ),
      'images': PerfResourceBucket(
        transferSizeKb: 66.0,
        decodedBodySizeKb: 65.7,
        count: 1,
        cachedCount: 0,
        opaqueCount: 0,
      ),
      'fonts': PerfResourceBucket(
        transferSizeKb: 60.0,
        decodedBodySizeKb: 47.4,
        count: 2,
        cachedCount: 0,
        opaqueCount: 0,
      ),
    },
    cachedCount: 0,
    networkCount: 8,
    opaqueCount: 0,
    allFromCache: false,
    jsHeapUsedMb: 36.2,
    jsHeapTotalMb: 60.0,
  );
}

void main() {
  group('PerfDebugOverlay', () {
    testWidgets('is hidden by default and toggles with Alt+P', (tester) async {
      final service = FakePerfTelemetryService(
        perfQueryEnabled: false,
        snapshot: _sampleSnapshot(totalReadyMs: 520.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [PerfDebugOverlay(telemetryService: service)],
            ),
          ),
        ),
      );

      expect(find.text('PERF DEBUG HUD'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(find.text('PERF DEBUG HUD'), findsOneWidget);
      expect(find.text('520 ms'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(find.text('PERF DEBUG HUD'), findsNothing);
    });

    testWidgets(
      'auto-shows on ?perf=1, saves baseline, and displays improvement delta',
      (tester) async {
        final service = FakePerfTelemetryService(
          perfQueryEnabled: true,
          snapshot: _sampleSnapshot(
            totalReadyMs: 636.0,
            assetsAndFontsMs: 235.0,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [PerfDebugOverlay(telemetryService: service)],
              ),
            ),
          ),
        );

        expect(find.text('PERF DEBUG HUD'), findsOneWidget);
        expect(find.text('636 ms'), findsOneWidget);

        await tester.tap(find.text('Save as Baseline'));
        await tester.pump();
        expect(service.saveCalls, 1);

        service.snapshot = _sampleSnapshot(
          totalReadyMs: 496.0,
          assetsAndFontsMs: 95.0,
        );
        await tester.tap(find.text('Refresh'));
        await tester.pump();

        expect(find.text('496 ms'), findsOneWidget);
        expect(find.text('-140ms (-22%)'), findsOneWidget);

        await tester.tap(find.text('Clear'));
        await tester.pump();
        expect(service.clearCalls, 1);
        expect(find.text('-140ms (-22%)'), findsNothing);
      },
    );

    testWidgets(
      'auto-refreshes post-app-ready when totalReadyMs is initially null',
      (tester) async {
        final service = FakePerfTelemetryService(
          perfQueryEnabled: true,
          snapshot: _sampleSnapshot(totalReadyMs: null, assetsAndFontsMs: null),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [PerfDebugOverlay(telemetryService: service)],
              ),
            ),
          ),
        );

        expect(find.text('PERF DEBUG HUD'), findsOneWidget);
        expect(find.text('—'), findsAtLeastNWidgets(2));

        service.snapshot = _sampleSnapshot(
          totalReadyMs: 485.0,
          assetsAndFontsMs: 88.0,
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('485 ms'), findsOneWidget);
        expect(find.text('88 ms'), findsOneWidget);
      },
    );
  });
}
