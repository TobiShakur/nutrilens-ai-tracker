import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../entities/imagen_plato.dart';
import '../entities/plato_detectado.dart';

abstract class ScannerRepository {
  /// Analyzes [imagen] via vision AI and optionally matches against [alacenaUsuario].
  /// Throws [ScannerFailure] on validation, auth, network, or empty-detection errors.
  Future<PlatoDetectado> escanearPlato({
    required ImagenPlato imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
    String languageCode = 'es',
  });
}
