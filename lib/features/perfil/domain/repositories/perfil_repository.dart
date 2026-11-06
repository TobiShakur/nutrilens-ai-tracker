import '../../../diario/domain/entities/diario_dia.dart';
import '../entities/configuracion_nutricional.dart';
import '../entities/resumen_semanal_metricas.dart';

abstract class PerfilRepository {
  Future<ConfiguracionNutricional> obtenerConfiguracion();
  Future<void> guardarConfiguracion(ConfiguracionNutricional configuracion);
  Future<ResumenSemanalMetricas> calcularMetricasSemana({
    required int offset,
    required List<DiarioDia> historialDias,
    required ConfiguracionNutricional config,
  });
}
