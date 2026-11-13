import 'dart:typed_data';
import '../entities/barcode_product_data.dart';

/// Contrato para la lectura y resolución de información nutricional mediante
/// código de barras o visión artificial sobre etiquetas y envases.
abstract class BarcodeProductService {
  /// Busca un producto por código GS1 en Open Food Facts con fallback opcional a IA.
  /// Retorna `null` únicamente cuando el producto no existe en ninguna fuente.
  /// Lanza `BarcodeScanFailure` ante errores de red, timeout, formato o API.
  Future<BarcodeProductData?> buscarPorCodigoBarras(String codigo);

  /// Analiza una fotografía de envase, código o tabla nutricional con Gemini Vision.
  /// Retorna `null` si no se detectó producto legible.
  /// Lanza `BarcodeScanFailure` ante imagen inválida, falta de API key o error de API/red.
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
  });
}
