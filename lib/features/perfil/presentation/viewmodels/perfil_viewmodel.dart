// VIEWMODEL DEL PERFIL Y MÉTRICAS NUTRICIONALES (PATRÓN MVVM)
// Gestiona la configuración de metas (Kcal y macros), bandas de tolerancia asimétricas
// y el cálculo reactivo del resumen semanal (lunes a domingo con navegación temporal).

import 'package:flutter/foundation.dart';
import '../../../diario/domain/entities/diario_dia.dart';
import '../../domain/entities/configuracion_nutricional.dart';
import '../../domain/entities/resumen_semanal_metricas.dart';
import '../../domain/repositories/perfil_repository.dart';

class PerfilViewModel extends ChangeNotifier {
  final PerfilRepository repository;

  ConfiguracionNutricional _config = const ConfiguracionNutricional();
  ResumenSemanalMetricas? _metricas;
  int _semanaOffset = 0;
  bool _cargando = false;

  PerfilViewModel({required this.repository});

  ConfiguracionNutricional get config => _config;
  ResumenSemanalMetricas? get metricas => _metricas;
  int get semanaOffset => _semanaOffset;
  bool get cargando => _cargando;

  Future<void> inicializar(List<DiarioDia> historial) async {
    _cargando = true;
    notifyListeners();

    _config = await repository.obtenerConfiguracion();
    _metricas = await repository.calcularMetricasSemana(
      offset: _semanaOffset,
      historialDias: historial,
      config: _config,
    );

    _cargando = false;
    notifyListeners();
  }

  Future<void> cambiarSemana(int offset, List<DiarioDia> historial) async {
    if (_semanaOffset == offset) return;
    _semanaOffset = offset;
    _cargando = true;
    notifyListeners();

    _metricas = await repository.calcularMetricasSemana(
      offset: _semanaOffset,
      historialDias: historial,
      config: _config,
    );

    _cargando = false;
    notifyListeners();
  }

  Future<void> recalcularMetricas(List<DiarioDia> historial) async {
    _metricas = await repository.calcularMetricasSemana(
      offset: _semanaOffset,
      historialDias: historial,
      config: _config,
    );
    notifyListeners();
  }

  Future<void> actualizarMetas({
    required int metaCalorias,
    required double metaProteinas,
    required double metaCarbos,
    required double metaGrasas,
    required List<DiarioDia> historial,
  }) async {
    _config = _config.copyWith(
      metaCalorias: metaCalorias,
      metaProteinas: metaProteinas,
      metaCarbos: metaCarbos,
      metaGrasas: metaGrasas,
    );
    await repository.guardarConfiguracion(_config);
    await recalcularMetricas(historial);
  }

  Future<void> ajustarToleranciaInferior(
    double delta,
    List<DiarioDia> historial,
  ) async {
    final nueva = (_config.toleranciaInferior + delta).clamp(0.02, 0.30);
    _config = _config.copyWith(
      toleranciaInferior: double.parse(nueva.toStringAsFixed(2)),
    );
    await repository.guardarConfiguracion(_config);
    await recalcularMetricas(historial);
  }

  Future<void> ajustarToleranciaSuperior(
    double delta,
    List<DiarioDia> historial,
  ) async {
    final nueva = (_config.toleranciaSuperior + delta).clamp(0.02, 0.30);
    _config = _config.copyWith(
      toleranciaSuperior: double.parse(nueva.toStringAsFixed(2)),
    );
    await repository.guardarConfiguracion(_config);
    await recalcularMetricas(historial);
  }

  Future<void> fijarTolerancias({
    required double inferior,
    required double superior,
    required List<DiarioDia> historial,
  }) async {
    _config = _config.copyWith(
      toleranciaInferior: inferior.clamp(0.02, 0.30),
      toleranciaSuperior: superior.clamp(0.02, 0.30),
    );
    await repository.guardarConfiguracion(_config);
    await recalcularMetricas(historial);
  }
}
