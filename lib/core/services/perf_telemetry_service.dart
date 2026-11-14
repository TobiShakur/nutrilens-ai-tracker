import 'perf_telemetry_models.dart';

/// Abstraction for reading boot/network telemetry and persisting baselines.
abstract interface class PerfTelemetryService {
  static const String baselineStorageKey = 'nutrilens_perf_baseline_v1';

  bool isPerfQueryEnabled();
  PortfolioPerfSnapshot? readSnapshot();
  PortfolioPerfSnapshot? loadBaseline();
  void saveBaseline(PortfolioPerfSnapshot snapshot);
  void clearBaseline();
}
