import 'package:flutter/foundation.dart';

/// Alimento que más aportó a un macronutriente específico en el período.
@immutable
class TopIngredienteMacro {
  final String nombre;
  final String emoji;
  final double aporteMacroGramos;
  final double gramosAlimentoTotales;
  final int vecesConsumido;
  final String tipoMacro; // 'Proteínas', 'Carbohidratos', 'Grasas'

  const TopIngredienteMacro({
    required this.nombre,
    required this.emoji,
    required this.aporteMacroGramos,
    required this.gramosAlimentoTotales,
    required this.vecesConsumido,
    required this.tipoMacro,
  });

  String get resumenAporte =>
      '${aporteMacroGramos.toStringAsFixed(1)}g aportados · $vecesConsumido ${vecesConsumido == 1 ? "comida" : "comidas"}';
}

/// Métricas analíticas consolidadas de una semana específica.
@immutable
class ResumenSemanalMetricas {
  final String semanaTitulo;
  final int offset;
  final int rachaActualDias;
  final int diasCumplidos;
  final int totalDiasRegistrados;
  final double porcentajeCumplimiento;
  final int healthScorePromedio;
  final double ratioAprovechamientoAlacena; // 0.0 a 1.0
  final TopIngredienteMacro? topProteina;
  final TopIngredienteMacro? topCarbos;
  final TopIngredienteMacro? topGrasas;

  const ResumenSemanalMetricas({
    required this.semanaTitulo,
    required this.offset,
    required this.rachaActualDias,
    required this.diasCumplidos,
    required this.totalDiasRegistrados,
    required this.porcentajeCumplimiento,
    required this.healthScorePromedio,
    required this.ratioAprovechamientoAlacena,
    this.topProteina,
    this.topCarbos,
    this.topGrasas,
  });

  String get cumplimientoLabel =>
      '${(porcentajeCumplimiento * 100).round()}% ($diasCumplidos/$totalDiasRegistrados días)';

  String get alacenaRatioLabel =>
      '${(ratioAprovechamientoAlacena * 100).round()}% alacena propia';
}
