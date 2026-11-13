import 'dart:typed_data';

/// Reglas puras de dominio para validación GS1 de códigos de barras y payloads de etiquetas.
abstract final class BarcodeValidator {
  /// Límite de tamaño de imagen para etiquetas (10 MB).
  static const int maxBytesEtiqueta = 10 * 1024 * 1024;

  /// Tipos MIME permitidos para captura y envío a Gemini Vision.
  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  static final RegExp _estructuraGs1 = RegExp(r'^(\d{8}|\d{12,14})$');

  /// Conserva únicamente dígitos numéricos del código ingresado.
  static String limpiar(String raw) =>
      raw.trim().replaceAll(RegExp(r'[^0-9]'), '');

  /// Verifica que el código ya limpio tenga longitud EAN-8, UPC-A (12), EAN-13 o GTIN-14.
  static bool esEstructuraValida(String codigoLimpio) =>
      _estructuraGs1.hasMatch(codigoLimpio);

  /// Valida formato GS1 (8, 12, 13 o 14 dígitos) y dígito verificador mod-10.
  static bool esCodigoValido(String raw) {
    final limpio = limpiar(raw);
    if (!esEstructuraValida(limpio)) return false;

    final checkDigit = limpio.codeUnitAt(limpio.length - 1) - 48;
    var suma = 0;
    var posicionDesdeDerecha = 1;

    for (var i = limpio.length - 2; i >= 0; i--) {
      final digito = limpio.codeUnitAt(i) - 48;
      final multiplicador = posicionDesdeDerecha.isOdd ? 3 : 1;
      suma += digito * multiplicador;
      posicionDesdeDerecha++;
    }

    final esperado = (10 - (suma % 10)) % 10;
    return esperado == checkDigit;
  }

  /// Normaliza un MIME type para comparación contra la allowlist.
  static String normalizarMime(String mimeType) =>
      mimeType.trim().toLowerCase();

  /// Valida bytes y MIME type para análisis de etiquetas.
  /// Retorna `null` si es válido, o `'vacia' | 'tamano_excedido' | 'mime_no_soportado'`.
  static String? validarImagenEtiqueta(Uint8List bytes, String mimeType) {
    if (bytes.isEmpty) return 'vacia';
    if (bytes.length > maxBytesEtiqueta) return 'tamano_excedido';
    if (!allowedMimeTypes.contains(normalizarMime(mimeType))) {
      return 'mime_no_soportado';
    }
    return null;
  }
}
