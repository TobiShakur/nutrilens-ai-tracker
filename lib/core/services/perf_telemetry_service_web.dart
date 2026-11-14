import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'perf_telemetry_models.dart';
import 'perf_telemetry_service.dart';

@JS('__portfolioPerf')
external _JsPortfolioPerf? get _jsPortfolioPerf;

extension type _JsPortfolioPerf(JSObject _) implements JSObject {
  external JSString snapshotJson();
}

/// Web implementation reading `window.__portfolioPerf` and `localStorage`.
final class PlatformPerfTelemetryService implements PerfTelemetryService {
  @override
  bool isPerfQueryEnabled() {
    if (Uri.base.queryParameters['perf'] == '1') {
      return true;
    }
    try {
      final search = web.window.location.search;
      if (search.isNotEmpty) {
        final normalized = search.startsWith('?')
            ? search.substring(1)
            : search;
        return Uri.splitQueryString(normalized)['perf'] == '1';
      }
    } catch (_) {
      // Ignore malformed query strings.
    }
    return false;
  }

  @override
  PortfolioPerfSnapshot? readSnapshot() {
    try {
      final perfObj = _jsPortfolioPerf;
      if (perfObj == null) {
        return null;
      }
      final rawJson = perfObj.snapshotJson().toDart;
      return PortfolioPerfSnapshot.tryDecodeJson(rawJson);
    } catch (_) {
      return null;
    }
  }

  @override
  PortfolioPerfSnapshot? loadBaseline() {
    try {
      final raw = web.window.localStorage.getItem(
        PerfTelemetryService.baselineStorageKey,
      );
      return PortfolioPerfSnapshot.tryDecodeJson(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  void saveBaseline(PortfolioPerfSnapshot snapshot) {
    try {
      web.window.localStorage.setItem(
        PerfTelemetryService.baselineStorageKey,
        snapshot.toJsonString(),
      );
    } catch (_) {
      // Ignore storage quota / private mode errors.
    }
  }

  @override
  void clearBaseline() {
    try {
      web.window.localStorage.removeItem(
        PerfTelemetryService.baselineStorageKey,
      );
    } catch (_) {
      // Ignore storage access errors.
    }
  }
}
