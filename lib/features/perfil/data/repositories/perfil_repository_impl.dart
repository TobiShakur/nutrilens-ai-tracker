import '../../../../core/storage/local_storage_service.dart';
import '../../../diario/domain/entities/diario_dia.dart';
import '../../domain/entities/configuracion_nutricional.dart';
import '../../domain/entities/resumen_semanal_metricas.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../datasources/perfil_datasource.dart';

class PerfilRepositoryImpl implements PerfilRepository {
  final PerfilDataSource _dataSource;

  PerfilRepositoryImpl({
    PerfilDataSource? dataSource,
    LocalStorageService? storageService,
  }) : _dataSource =
           dataSource ?? PerfilDataSourceImpl(storageService: storageService);

  @override
  Future<ConfiguracionNutricional> obtenerConfiguracion() {
    return _dataSource.obtenerConfiguracion();
  }

  @override
  Future<void> guardarConfiguracion(ConfiguracionNutricional configuracion) {
    return _dataSource.guardarConfiguracion(configuracion);
  }

  @override
  Future<ResumenSemanalMetricas> calcularMetricasSemana({
    required int offset,
    required List<DiarioDia> historialDias,
    required ConfiguracionNutricional config,
  }) {
    return _dataSource.calcularMetricasSemana(
      offset: offset,
      historialDias: historialDias,
      config: config,
    );
  }
}
