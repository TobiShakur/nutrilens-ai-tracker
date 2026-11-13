/// Constantes de configuración de APIs de IA para NutriLens.
///
/// ADVERTENCIA DE SEGURIDAD:
/// `GEMINI_API_KEY` vía `--dart-define` está pensada **exclusivamente para
/// entorno de desarrollo o demostración local**. En producción, la aplicación
/// debe comunicarse con un backend proxy (ej: Cloudflare Worker) mediante
/// `GEMINI_PROXY_URL` o `endpointUrl`, evitando embeber secretos en el cliente.
abstract final class ApiConstants {
  static const String _primaryModelPath =
      '/v1beta/models/gemini-2.5-flash:generateContent';
  static const String _fallbackModelPath =
      '/v1beta/models/gemini-flash-latest:generateContent';

  /// Clave de API inyectada en tiempo de compilación (--dart-define=GEMINI_API_KEY=...).
  /// Uso exclusivo para desarrollo/demo local.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// URL base del proxy seguro de Gemini (--dart-define=GEMINI_PROXY_URL=...).
  static const String geminiProxyUrl = String.fromEnvironment(
    'GEMINI_PROXY_URL',
  );

  /// Indica si la aplicación tiene una clave configurada en su entorno local.
  static bool get tieneGeminiApiKey => geminiApiKey.isNotEmpty;

  /// Indica si Gemini está configurado (vía proxy seguro o API key local).
  static bool get tieneGeminiConfigurado =>
      tieneGeminiApiKey || geminiProxyUrl.trim().isNotEmpty;

  /// Resuelve las URIs primaria y fallback para un proxy Gemini compatible con
  /// la API REST `/v1beta/models/*:generateContent`.
  ///
  /// Retorna `null` si [rawProxyUrl] está vacío. Exige HTTPS en hosts remotos
  /// y permite HTTP únicamente en `localhost` o `127.0.0.1` para pruebas locales.
  static ({Uri primary, Uri fallback})? resolveGeminiProxyUris(
    String rawProxyUrl,
  ) {
    final trimmed = rawProxyUrl.trim();
    if (trimmed.isEmpty) return null;

    final base = Uri.tryParse(trimmed);
    if (base == null || base.host.isEmpty) {
      throw const FormatException('Invalid GEMINI_PROXY_URL');
    }

    final scheme = base.scheme.toLowerCase();
    final host = base.host.toLowerCase();
    final isLocalHttp =
        scheme == 'http' && (host == 'localhost' || host == '127.0.0.1');
    if (scheme != 'https' && !isLocalHttp) {
      throw const FormatException('GEMINI_PROXY_URL must use HTTPS');
    }

    final cleanBasePath = base.path.replaceAll(RegExp(r'/+$'), '');
    return (
      primary: Uri(
        scheme: scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: '$cleanBasePath$_primaryModelPath',
      ),
      fallback: Uri(
        scheme: scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: '$cleanBasePath$_fallbackModelPath',
      ),
    );
  }
}
