import 'package:flutter/foundation.dart';
import '../../../../core/failures/scanner_failure.dart';
import '../../../diario/presentation/viewmodels/health_score_eval_state.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/entities/plato_detectado.dart';

export '../../../../core/failures/scanner_failure.dart' show ScannerErrorType;

/// Immutable state machine for [ScannerViewModel].
@immutable
sealed class ScannerState {
  const ScannerState();
}

final class ScannerIdle extends ScannerState {
  const ScannerIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScannerIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class ScannerCapturing extends ScannerState {
  const ScannerCapturing();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScannerCapturing;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class ScannerAnalyzing extends ScannerState {
  final ImagenPlato imagen;

  const ScannerAnalyzing({required this.imagen});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerAnalyzing && imagen == other.imagen;

  @override
  int get hashCode => Object.hash(runtimeType, imagen);
}

final class ScannerSuccess extends ScannerState {
  final PlatoDetectado plato;
  final ImagenPlato? imagen;
  final bool esManual;
  final bool healthScoreDesactualizado;
  final HealthScoreEvalState healthScoreEvalState;

  const ScannerSuccess({
    required this.plato,
    this.imagen,
    required this.esManual,
    this.healthScoreDesactualizado = false,
    this.healthScoreEvalState = const HealthScoreEvalIdle(),
  });

  ScannerSuccess copyWith({
    PlatoDetectado? plato,
    ImagenPlato? imagen,
    bool? esManual,
    bool? healthScoreDesactualizado,
    HealthScoreEvalState? healthScoreEvalState,
  }) {
    return ScannerSuccess(
      plato: plato ?? this.plato,
      imagen: imagen ?? this.imagen,
      esManual: esManual ?? this.esManual,
      healthScoreDesactualizado:
          healthScoreDesactualizado ?? this.healthScoreDesactualizado,
      healthScoreEvalState: healthScoreEvalState ?? this.healthScoreEvalState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerSuccess &&
          plato == other.plato &&
          imagen == other.imagen &&
          esManual == other.esManual &&
          healthScoreDesactualizado == other.healthScoreDesactualizado &&
          healthScoreEvalState == other.healthScoreEvalState;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    plato,
    imagen,
    esManual,
    healthScoreDesactualizado,
    healthScoreEvalState,
  );
}

enum ScannerErrorDetail {
  none,
  missingImage,
  emptyImage,
  tooLargeImage,
  unsupportedFormat,
  cameraPermission,
  galleryPermission,
  emptyIngredients,
  noFoodDetected,
}

final class ScannerError extends ScannerState {
  final String message;
  final ScannerErrorType type;
  final ScannerErrorDetail detail;
  final ImagenPlato? imagen;

  const ScannerError({
    required this.message,
    required this.type,
    this.detail = ScannerErrorDetail.none,
    this.imagen,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerError &&
          message == other.message &&
          type == other.type &&
          detail == other.detail &&
          imagen == other.imagen;

  @override
  int get hashCode => Object.hash(runtimeType, message, type, detail, imagen);
}
