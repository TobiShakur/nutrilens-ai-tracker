import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/ingrediente_alacena.dart';
import '../../domain/repositories/alacena_repository.dart';
import '../datasources/alacena_local_datasource.dart';

class AlacenaRepositoryImpl implements AlacenaRepository {
  final AlacenaLocalDataSource _dataSource;

  AlacenaRepositoryImpl({
    AlacenaLocalDataSource? dataSource,
    LocalStorageService? storageService,
  }) : _dataSource =
           dataSource ??
           AlacenaLocalDataSourceImpl(storageService: storageService);

  @override
  Future<List<IngredienteAlacena>> obtenerIngredientes() {
    return _dataSource.getIngredientes();
  }

  @override
  Future<IngredienteAlacena> agregarIngrediente(
    IngredienteAlacena ingrediente,
  ) {
    return _dataSource.saveIngrediente(ingrediente);
  }

  @override
  Future<IngredienteAlacena> actualizarIngrediente(
    IngredienteAlacena ingrediente,
  ) {
    return _dataSource.saveIngrediente(ingrediente);
  }

  @override
  Future<bool> eliminarIngrediente(String id) {
    return _dataSource.deleteIngrediente(id);
  }

  @override
  Future<List<IngredienteAlacena>> buscar(String termino) async {
    final todos = await _dataSource.getIngredientes();
    final query = termino.trim().toLowerCase();
    if (query.isEmpty) return todos;

    return todos.where((item) {
      final matchNombre = item.nombre.toLowerCase().contains(query);
      final matchMarca = item.marca?.toLowerCase().contains(query) ?? false;
      return matchNombre || matchMarca;
    }).toList();
  }
}
