import '../../../../core/failures/scanner_failure.dart';
import '../../domain/entities/alimento_conflicto_marca.dart';
import '../../domain/entities/plato_detectado.dart';
import 'comida_ingrediente_model.dart';

/// DTO para parsear la respuesta estructurada de Gemini Vision.
class PlatoDetectadoModel {
  final String nombrePlato;
  final int healthScore;
  final String explicacionHealthScore;
  final List<ComidaIngredienteModel> ingredientes;

  const PlatoDetectadoModel({
    required this.nombrePlato,
    required this.healthScore,
    this.explicacionHealthScore =
        'Buen balance de nutrientes y alimentos frescos.',
    required this.ingredientes,
  });

  factory PlatoDetectadoModel.fromJson(Map<String, dynamic> json) {
    final rawIngredientes = json['ingredientes'] as List<dynamic>? ?? [];
    final items = rawIngredientes
        .whereType<Map<String, dynamic>>()
        .map(ComidaIngredienteModel.fromJson)
        .toList();

    final explicacionRaw = json['explicacionHealthScore'] as String?;
    final explicacion =
        (explicacionRaw != null && explicacionRaw.trim().isNotEmpty)
        ? explicacionRaw.trim()
        : 'Buen balance de nutrientes y alimentos frescos.';

    final rawScore = json['healthScore'];
    if (rawScore is! num || !rawScore.isFinite) {
      throw const ScannerInvalidResponseFailure();
    }
    final parsedScore = rawScore.round().clamp(0, 100);

    return PlatoDetectadoModel(
      nombrePlato:
          (json['nombrePlato'] as String?)?.trim() ??
          (json['nombre'] as String?)?.trim() ??
          'Plato Detectado',
      healthScore: parsedScore,
      explicacionHealthScore: explicacion,
      ingredientes: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombrePlato': nombrePlato,
    'healthScore': healthScore,
    'explicacionHealthScore': explicacionHealthScore,
    'ingredientes': ingredientes.map((i) => i.toJson()).toList(),
  };

  PlatoDetectado toEntity({
    required String id,
    List<AlimentoConflictoMarca> conflictosMarcas = const [],
  }) {
    return PlatoDetectado(
      id: id,
      nombreSugerido: nombrePlato,
      healthScore: healthScore,
      explicacionHealthScore: explicacionHealthScore,
      ingredientes: ingredientes
          .asMap()
          .entries
          .map((e) => e.value.toEntity(id: '${id}_ing_${e.key}'))
          .toList(),
      conflictosMarcas: conflictosMarcas,
    );
  }
}
