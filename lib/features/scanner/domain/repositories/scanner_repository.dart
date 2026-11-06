import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../entities/imagen_plato.dart';
import '../entities/plato_detectado.dart';

abstract class ScannerRepository {
  /// Analiza una toma fotográfica y detecta los ingredientes, contrastando opcionalmente
  /// con los alimentos disponibles en la Alacena del usuario.
  Future<PlatoDetectado> escanearPlato({
    ImagenPlato? imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  });
}
