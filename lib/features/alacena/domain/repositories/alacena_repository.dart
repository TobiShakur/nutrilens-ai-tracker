import '../entities/ingrediente_alacena.dart';

abstract class AlacenaRepository {
  Future<List<IngredienteAlacena>> obtenerIngredientes();
  Future<IngredienteAlacena> agregarIngrediente(IngredienteAlacena ingrediente);
  Future<IngredienteAlacena> actualizarIngrediente(
    IngredienteAlacena ingrediente,
  );
  Future<bool> eliminarIngrediente(String id);
  Future<List<IngredienteAlacena>> buscar(String termino);
}
