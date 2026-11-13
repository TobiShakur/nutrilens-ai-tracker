import 'package:flutter/foundation.dart';

/// Utilidad pura para sanitizar logs de red en modo debug sin exponer secretos.
abstract final class LogSanitizer {
  static final RegExp _sensitiveQueryParam = RegExp(
    r'([?&](?:key|token|auth|access_token|api_key)=)([^&\s]+)',
    caseSensitive: false,
  );

  static final RegExp _googleApiKeyPattern = RegExp(r'AIza[0-9A-Za-z_\-]{10,}');

  /// Redacta parámetros de consulta sensibles y posibles claves embebidas.
  static String sanitizarMensaje(String input) {
    var sanitized = input.replaceAllMapped(
      _sensitiveQueryParam,
      (m) => '${m.group(1)}[REDACTED]',
    );
    sanitized = sanitized.replaceAll(_googleApiKeyPattern, '[REDACTED_KEY]');
    return sanitized;
  }

  /// Trunca el cuerpo de respuesta a un máximo seguro (por defecto 200 caracteres).
  static String truncarBody(String body, {int maxLength = 200}) {
    final limpio = sanitizarMensaje(
      body,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (limpio.length <= maxLength) return limpio;
    return '${limpio.substring(0, maxLength)}...';
  }

  /// Emite un log en [kDebugMode] sin incluir headers ni credenciales.
  static void logDebug(String tag, String mensaje, {String? body}) {
    if (!kDebugMode) return;
    final textoLimpio = sanitizarMensaje(mensaje);
    if (body == null || body.isEmpty) {
      debugPrint('[$tag] $textoLimpio');
      return;
    }
    debugPrint('[$tag] $textoLimpio | body=${truncarBody(body)}');
  }
}
