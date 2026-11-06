import '../../domain/entities/imagen_plato.dart';
import '../models/plato_detectado_model.dart';

/// Contrato para el DataSource remoto de IA (Gemini Vision / Firebase AI Logic).
abstract class ScannerRemoteDataSource {
  Future<PlatoDetectadoModel> analizarFotoPlato({
    required ImagenPlato imagen,
    required List<String> nombresAlacena,
  });
}
