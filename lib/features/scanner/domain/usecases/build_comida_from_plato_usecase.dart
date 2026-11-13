import '../../../diario/domain/entities/comida_item.dart';
import '../entities/plato_detectado.dart';

/// Pure domain use case that assembles a [ComidaItem] from a reviewed [PlatoDetectado].
class BuildComidaFromPlatoUseCase {
  final DateTime Function() _clock;

  BuildComidaFromPlatoUseCase({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Builds a [ComidaItem] for [DiarioViewModel] from [plato] and user metadata.
  ///
  /// Throws [ArgumentError] if [plato.ingredientes] is empty.
  ComidaItem call({
    required PlatoDetectado plato,
    required String titulo,
    required String tipoComida,
    bool healthScoreDesactualizado = false,
    DateTime? now,
  }) {
    if (plato.ingredientes.isEmpty) {
      throw ArgumentError('Cannot build a meal from an empty ingredient list.');
    }

    final timestamp = now ?? _clock();
    final trimmedTitle = titulo.trim();
    final normalizedTitle = trimmedTitle.isEmpty ? 'Comida' : trimmedTitle;
    final normalizedType = tipoComida.trim().toUpperCase();
    final formattedHour =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final rawExplanation = plato.explicacionHealthScore?.trim();
    final normalizedExplanation =
        (rawExplanation != null && rawExplanation.isNotEmpty)
        ? rawExplanation
        : null;

    // Omit icono so ComidaItem's default applies without UI icon dependencies here.
    return ComidaItem(
      id: 'comida_${timestamp.microsecondsSinceEpoch}',
      titulo: normalizedTitle,
      tipoComida: normalizedType.isEmpty ? null : normalizedType,
      descripcion: plato.esManual ? null : plato.nombreSugerido,
      healthScore: plato.healthScore,
      explicacionHealthScore: normalizedExplanation,
      healthScoreDesactualizado:
          plato.healthScore != null && healthScoreDesactualizado,
      hora: formattedHour,
      ingredientes: List.unmodifiable(plato.ingredientes),
    );
  }
}
