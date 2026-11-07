import 'dart:typed_data';
import '../entities/barcode_product_data.dart';

/// Contrato para la lectura y resolución de información nutricional mediante
/// código de barras o visión artificial sobre etiquetas y envases.
abstract class BarcodeProductService {
  /// Busca un producto por su código de barras numérico en Open Food Facts,
  /// con fallback heurístico o de IA si no se encuentra registrado.
  Future<BarcodeProductData?> buscarPorCodigoBarras(String codigo);

  /// Analiza una fotografía de envase, código o tabla nutricional con Gemini Vision.
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
  });
}
