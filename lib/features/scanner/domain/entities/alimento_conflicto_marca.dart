import 'package:flutter/foundation.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';

/// Representa una ambigüedad detectada por la IA cuando el usuario tiene
/// más de una marca del mismo alimento en su Alacena (ej: dos panes de molde de marcas distintas).
@immutable
class AlimentoConflictoMarca {
  final String nombreGenerico;
  final double gramosDetectados;
  final List<IngredienteAlacena> opcionesAlacena;

  const AlimentoConflictoMarca({
    required this.nombreGenerico,
    required this.gramosDetectados,
    required this.opcionesAlacena,
  });
}
