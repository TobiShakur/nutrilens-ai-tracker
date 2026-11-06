import '../entities/imagen_plato.dart';

/// Contrato abstracto para captura de imágenes (agnóstico de plugins externos de hardware).
abstract class ImageCaptureService {
  Future<ImagenPlato?> capturarConCamara();
  Future<ImagenPlato?> seleccionarDeGaleria();
}
