import '../../../../core/failures/scanner_failure.dart';

/// Pure domain mapper converting [ScannerFailure] into sanitized Spanish user copy
/// without exposing raw exceptions, URLs, headers, or API keys.
abstract final class HealthScoreFailureMapper {
  static ({String message, ScannerErrorType type}) map(ScannerFailure failure) {
    return switch (failure) {
      ScannerApiKeyMissingFailure() => (
        message:
            'La evaluación con IA requiere configurar GEMINI_API_KEY en este entorno.',
        type: ScannerErrorType.missingApiKey,
      ),
      ScannerNetworkFailure() => (
        message:
            'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.',
        type: ScannerErrorType.network,
      ),
      ScannerTimeoutFailure() => (
        message:
            'La evaluación tardó demasiado. Intentá nuevamente en unos segundos.',
        type: ScannerErrorType.timeout,
      ),
      ScannerRateLimitFailure() => (
        message:
            'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.',
        type: ScannerErrorType.rateLimit,
      ),
      ScannerServiceUnavailableFailure() => (
        message:
            'El servicio de evaluación no está disponible en este momento. Probá más tarde.',
        type: ScannerErrorType.serviceUnavailable,
      ),
      ScannerInvalidResponseFailure() => (
        message:
            'No pudimos interpretar la evaluación nutricional. Intentá nuevamente.',
        type: ScannerErrorType.invalidResponse,
      ),
      ScannerEmptyIngredientsFailure() || ScannerNoFoodDetectedFailure() => (
        message:
            'Agregá al menos un ingrediente para calcular el Health Score.',
        type: ScannerErrorType.noFoodDetected,
      ),
      ScannerMissingImageFailure() || ScannerInvalidImageFailure() => (
        message:
            'No pudimos interpretar la evaluación nutricional. Intentá nuevamente.',
        type: ScannerErrorType.invalidResponse,
      ),
      ScannerPermissionDeniedFailure() => (
        message:
            'No pudimos completar la evaluación nutricional. Intentá nuevamente.',
        type: ScannerErrorType.permissionDenied,
      ),
    };
  }
}
