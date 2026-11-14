import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/services/perf_telemetry_models.dart';

void main() {
  group('PortfolioPerfSnapshot', () {
    test('decodes valid JSON and round-trips cleanly', () {
      const raw = '''
      {
        "version": 1,
        "renderer": "skwasm",
        "readySource": "flutter",
        "htmlFirstPaintMs": 22.4,
        "engineLoadMs": 210.0,
        "dartBootMs": 40.5,
        "assetsAndFontsMs": 95.1,
        "totalReadyMs": 496.0,
        "transferSizeKb": 1245.5,
        "decodedBodySizeKb": 3020.0,
        "byType": {
          "wasm": { "transferSizeKb": 750.0, "decodedBodySizeKb": 1710.0, "count": 2, "cachedCount": 0, "opaqueCount": 0 },
          "images": { "transferSizeKb": 66.0, "decodedBodySizeKb": 65.7, "count": 1, "cachedCount": 0, "opaqueCount": 0 }
        },
        "cachedCount": 0,
        "networkCount": 9,
        "opaqueCount": 1,
        "allFromCache": false,
        "jsHeapUsedMb": 38.4,
        "jsHeapTotalMb": 64.0
      }
      ''';

      final parsed = PortfolioPerfSnapshot.tryDecodeJson(raw);
      expect(parsed, isNotNull);
      expect(parsed!.renderer, 'skwasm');
      expect(parsed.readySource, 'flutter');
      expect(parsed.totalReadyMs, 496.0);
      expect(parsed.bucket('images').decodedBodySizeKb, 65.7);
      expect(parsed.bucket('fonts').count, 0);
      expect(parsed.jsHeapUsedMb, 38.4);

      final reparsed = PortfolioPerfSnapshot.tryDecodeJson(
        parsed.toJsonString(),
      );
      expect(reparsed, isNotNull);
      expect(reparsed!.totalReadyMs, 496.0);
      expect(reparsed.bucket('wasm').transferSizeKb, 750.0);
    });

    test('returns null for empty or malformed JSON', () {
      expect(PortfolioPerfSnapshot.tryDecodeJson(null), isNull);
      expect(PortfolioPerfSnapshot.tryDecodeJson(''), isNull);
      expect(PortfolioPerfSnapshot.tryDecodeJson('{bad json'), isNull);
      expect(PortfolioPerfSnapshot.tryDecodeJson('[1, 2, 3]'), isNull);
    });
  });

  group('PerfMetricDelta', () {
    test('computes improvement and regression deltas accurately', () {
      final improved = PerfMetricDelta.compute(current: 496.0, baseline: 636.0);
      expect(improved, isNotNull);
      expect(improved!.improved, isTrue);
      expect(improved.format('ms'), '-140ms (-22%)');

      final regressed = PerfMetricDelta.compute(
        current: 550.0,
        baseline: 500.0,
      );
      expect(regressed, isNotNull);
      expect(regressed!.improved, isFalse);
      expect(regressed.format('ms'), '+50ms (+10%)');

      expect(PerfMetricDelta.compute(current: 500.0, baseline: 500.0), isNull);
    });
  });
}
