/// Constantes de configuración de APIs de IA para NutriLens.
///
/// ADVERTENCIA DE SEGURIDAD:
/// `GEMINI_API_KEY` vía `--dart-define` está pensada **exclusivamente para
/// entorno de desarrollo o demostración local**. En producción, la aplicación
/// debe comunicarse con un backend proxy autenticado (Firebase Auth + App Check)
/// mediante `endpointUrl`, evitando embeber secretos en el binario cliente.
abstract final class ApiConstants {
  /// Clave de API inyectada en tiempo de compilación (--dart-define=GEMINI_API_KEY=...).
  /// Uso exclusivo para desarrollo/demo local.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Indica si la aplicación tiene una clave configurada en su entorno local.
  static bool get tieneGeminiApiKey => geminiApiKey.isNotEmpty;
}
