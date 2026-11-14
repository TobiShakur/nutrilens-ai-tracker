import 'perf_telemetry_models.dart';
import 'perf_telemetry_service.dart';

/// Non-web / Dart VM fallback implementation for tests.
final class PlatformPerfTelemetryService implements PerfTelemetryService {
  PortfolioPerfSnapshot? _baseline;

  @override
  bool isPerfQueryEnabled() => Uri.base.queryParameters['perf'] == '1';

  @override
  PortfolioPerfSnapshot? readSnapshot() => null;

  @override
  PortfolioPerfSnapshot? loadBaseline() => _baseline;

  @override
  void saveBaseline(PortfolioPerfSnapshot snapshot) {
    _baseline = snapshot;
  }

  @override
  void clearBaseline() {
    _baseline = null;
  }
}
