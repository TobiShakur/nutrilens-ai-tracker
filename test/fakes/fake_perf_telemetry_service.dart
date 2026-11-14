import 'package:nutrilens_provider/core/services/perf_telemetry_models.dart';
import 'package:nutrilens_provider/core/services/perf_telemetry_service.dart';

final class FakePerfTelemetryService implements PerfTelemetryService {
  FakePerfTelemetryService({
    this.perfQueryEnabled = false,
    this.snapshot,
    this.baseline,
  });

  bool perfQueryEnabled;
  PortfolioPerfSnapshot? snapshot;
  PortfolioPerfSnapshot? baseline;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  bool isPerfQueryEnabled() => perfQueryEnabled;

  @override
  PortfolioPerfSnapshot? readSnapshot() => snapshot;

  @override
  PortfolioPerfSnapshot? loadBaseline() => baseline;

  @override
  void saveBaseline(PortfolioPerfSnapshot snapshot) {
    saveCalls += 1;
    baseline = snapshot;
  }

  @override
  void clearBaseline() {
    clearCalls += 1;
    baseline = null;
  }
}
