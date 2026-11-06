import 'package:flutter/foundation.dart';
import 'comida_item.dart';
import 'nivel_score.dart';

/// Entidad inmutable que representa el balance y comidas de un día específico
@immutable
class DiarioDia {
  final int diaIndex; // Índice cronológico del día
  final String diaNombre; // 'Do', 'Lu', 'Ma', 'Hoy', 'Ju', 'Vi', 'Sa'
  final String? titulo; // Etiqueta para píldora (e.g. 'Lu 26', 'Hoy', etc.)
  final int metaCalorias;
  final double metaProteinas;
  final double metaGrasas;
  final double metaCarbos;
  final List<ComidaItem> comidas;

  const DiarioDia({
    required this.diaIndex,
    required this.diaNombre,
    this.titulo,
    this.metaCalorias = 2135,
    this.metaProteinas = 190.0,
    this.metaGrasas = 130.0,
    this.metaCarbos = 64.0,
    this.comidas = const [],
  });

  String get labelPill => titulo ?? diaNombre;

  // ---------------------------------------------------------------------------
  // Fórmulas y Getters Calculados en Tiempo Real
  // ---------------------------------------------------------------------------

  /// Calorías actuales que lleva consumidas en el día
  int get caloriasActuales {
    return comidas.fold(0, (total, c) => total + c.calorias);
  }

  int get caloriasConsumidas => caloriasActuales;

  /// Calorías restantes para alcanzar la meta (0 si ya se pasó)
  int get caloriasRestantes {
    final restantes = metaCalorias - caloriasActuales;
    return restantes < 0 ? 0 : restantes;
  }

  /// Calorías extras consumidas por encima de la meta
  int get caloriasExtras {
    return caloriasActuales > metaCalorias
        ? (caloriasActuales - metaCalorias)
        : 0;
  }

  /// Ratio total de consumo respecto a la meta (1.0 = meta exacta, 1.5 = 50% de exceso, 2.3 = doble exceso)
  double get ratioTotal {
    if (metaCalorias <= 0) return 0.0;
    return caloriasActuales / metaCalorias;
  }

  bool get estaExcedido => caloriasActuales > metaCalorias;
  bool get estaExcedidoCritico => caloriasActuales > (metaCalorias * 2);

  /// Capa 1: Barra Verde (de 0.0 a 1.0)
  double get ratioVerde => ratioTotal.clamp(0.0, 1.0);

  /// Capa 2: Barra Naranja para el primer exceso (de 1.0 a 2.0)
  double get ratioNaranja {
    if (ratioTotal <= 1.0) return 0.0;
    return (ratioTotal - 1.0).clamp(0.0, 1.0);
  }

  /// Capa 3: Barra Roja para el segundo exceso crítico (> 2.0)
  double get ratioRojo {
    if (ratioTotal <= 2.0) return 0.0;
    return (ratioTotal - 2.0).clamp(0.0, 1.0);
  }

  double get proteinasConsumidas {
    return comidas.fold(0.0, (total, c) => total + c.proteinas);
  }

  double get grasasConsumidas {
    return comidas.fold(0.0, (total, c) => total + c.grasas);
  }

  double get carbosConsumidos {
    return comidas.fold(0.0, (total, c) => total + c.carbohidratos);
  }

  int get promedioHealthScore {
    if (comidas.isEmpty) return 0;
    final suma = comidas.fold(0, (total, c) => total + c.healthScore);
    return (suma / comidas.length).round();
  }

  NivelScore get nivelScore => NivelScore.desdeScore(
    score: promedioHealthScore,
    hayComidas: comidas.isNotEmpty,
  );

  int get cantidadComidas => comidas.length;

  DiarioDia copyWith({
    int? diaIndex,
    String? diaNombre,
    String? titulo,
    int? metaCalorias,
    double? metaProteinas,
    double? metaGrasas,
    double? metaCarbos,
    List<ComidaItem>? comidas,
  }) {
    return DiarioDia(
      diaIndex: diaIndex ?? this.diaIndex,
      diaNombre: diaNombre ?? this.diaNombre,
      titulo: titulo ?? this.titulo,
      metaCalorias: metaCalorias ?? this.metaCalorias,
      metaProteinas: metaProteinas ?? this.metaProteinas,
      metaGrasas: metaGrasas ?? this.metaGrasas,
      metaCarbos: metaCarbos ?? this.metaCarbos,
      comidas: comidas ?? this.comidas,
    );
  }

  Map<String, dynamic> toJson() => {
    'diaIndex': diaIndex,
    'diaNombre': diaNombre,
    'titulo': titulo,
    'metaCalorias': metaCalorias,
    'metaProteinas': metaProteinas,
    'metaGrasas': metaGrasas,
    'metaCarbos': metaCarbos,
    'comidas': comidas.map((c) => c.toJson()).toList(),
  };

  factory DiarioDia.fromJson(Map<String, dynamic> json) {
    final rawComidas = json['comidas'] as List<dynamic>? ?? [];
    return DiarioDia(
      diaIndex: (json['diaIndex'] as num).toInt(),
      diaNombre: json['diaNombre'] as String,
      titulo: json['titulo'] as String?,
      metaCalorias: (json['metaCalorias'] as num?)?.toInt() ?? 2135,
      metaProteinas: (json['metaProteinas'] as num?)?.toDouble() ?? 190.0,
      metaGrasas: (json['metaGrasas'] as num?)?.toDouble() ?? 130.0,
      metaCarbos: (json['metaCarbos'] as num?)?.toDouble() ?? 64.0,
      comidas: rawComidas
          .whereType<Map<String, dynamic>>()
          .map(ComidaItem.fromJson)
          .toList(),
    );
  }
}
