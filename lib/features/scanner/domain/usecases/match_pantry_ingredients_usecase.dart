import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../entities/alimento_conflicto_marca.dart';
import '../entities/plato_detectado.dart';

/// Matches AI-detected dish ingredients against the user's pantry inventory
/// and flags multi-brand ambiguities as [AlimentoConflictoMarca].
class MatchPantryIngredientsUseCase {
  final DateTime Function() _clock;

  MatchPantryIngredientsUseCase({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Links [detectedIngredients] to [alacenaUsuario] when [preferirAlacena] is true.
  PlatoDetectado call({
    required String dishName,
    required int? healthScore,
    required String? healthScoreExplanation,
    required List<ComidaIngrediente> detectedIngredients,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  }) {
    final nowMicros = _clock().microsecondsSinceEpoch;
    final List<ComidaIngrediente> matchedIngredients = [];
    final List<AlimentoConflictoMarca> brandConflicts = [];

    for (var i = 0; i < detectedIngredients.length; i++) {
      final detected = detectedIngredients[i];
      final searchedName = detected.nombre.trim().toLowerCase();

      if (preferirAlacena && searchedName.isNotEmpty) {
        final matches = alacenaUsuario.where((pantryItem) {
          final pantryName = pantryItem.nombre.trim().toLowerCase();
          if (pantryName.isEmpty) return false;
          return pantryName.contains(searchedName) ||
              searchedName.contains(pantryName);
        }).toList();

        if (matches.length == 1) {
          matchedIngredients.add(
            ComidaIngrediente.desdeAlacena(
              alacena: matches.first,
              gramos: detected.gramos,
            ),
          );
          continue;
        } else if (matches.length > 1) {
          brandConflicts.add(
            AlimentoConflictoMarca(
              nombreGenerico: detected.nombre,
              gramosDetectados: detected.gramos,
              opcionesAlacena: List.unmodifiable(matches),
            ),
          );
          matchedIngredients.add(
            ComidaIngrediente.desdeAlacena(
              alacena: matches.first,
              gramos: detected.gramos,
            ),
          );
          continue;
        }
      }

      matchedIngredients.add(detected.copyWith(id: 'ci_ai_${nowMicros}_$i'));
    }

    return PlatoDetectado(
      id: 'plato_$nowMicros',
      nombreSugerido: dishName,
      healthScore: healthScore,
      explicacionHealthScore: healthScoreExplanation,
      ingredientes: List.unmodifiable(matchedIngredients),
      conflictosMarcas: List.unmodifiable(brandConflicts),
      esManual: false,
    );
  }
}
