import 'package:flutter/foundation.dart';

/// Closed set of user-safe error categories for AI dish & Health Score operations.
enum ScannerErrorType {
  permissionDenied,
  invalidImage,
  missingApiKey,
  network,
  timeout,
  rateLimit,
  serviceUnavailable,
  invalidResponse,
  noFoodDetected,
  unknown,
}

/// Typed domain failures for the food photo scanner and Health Score pipelines.
///
/// Never stores raw exceptions, URLs, API keys, or headers so sensitive
/// infrastructure details cannot leak into UI state or error banners.
@immutable
sealed class ScannerFailure implements Exception {
  const ScannerFailure();
}

final class ScannerApiKeyMissingFailure extends ScannerFailure {
  const ScannerApiKeyMissingFailure();
}

final class ScannerMissingImageFailure extends ScannerFailure {
  const ScannerMissingImageFailure();
}

final class ScannerInvalidImageFailure extends ScannerFailure {
  /// Reason code: `'empty' | 'size_exceeded' | 'unsupported_mime'`.
  final String reason;
  const ScannerInvalidImageFailure(this.reason);
}

final class ScannerPermissionDeniedFailure extends ScannerFailure {
  final bool isCamera;
  const ScannerPermissionDeniedFailure({required this.isCamera});
}

final class ScannerNetworkFailure extends ScannerFailure {
  const ScannerNetworkFailure();
}

final class ScannerTimeoutFailure extends ScannerFailure {
  const ScannerTimeoutFailure();
}

final class ScannerRateLimitFailure extends ScannerFailure {
  const ScannerRateLimitFailure();
}

final class ScannerServiceUnavailableFailure extends ScannerFailure {
  final int? statusCode;
  const ScannerServiceUnavailableFailure({this.statusCode});
}

final class ScannerInvalidResponseFailure extends ScannerFailure {
  const ScannerInvalidResponseFailure();
}

final class ScannerNoFoodDetectedFailure extends ScannerFailure {
  const ScannerNoFoodDetectedFailure();
}

final class ScannerEmptyIngredientsFailure extends ScannerFailure {
  const ScannerEmptyIngredientsFailure();
}
