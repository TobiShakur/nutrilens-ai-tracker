/// Constantes de configuración de APIs de IA para NutriLens.
abstract final class ApiConstants {
  /// Clave de API inyectada en tiempo de compilación (--dart-define=GEMINI_API_KEY=...).
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Indica si la aplicación tiene una clave configurada en su entorno.
  static bool get tieneGeminiApiKey => geminiApiKey.isNotEmpty;
}
