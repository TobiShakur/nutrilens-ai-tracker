import 'package:flutter/material.dart';
import 'comida_ingrediente.dart';

/// Entidad inmutable de una Comida registrada en el diario, compuesta por una lista de ingredientes
@immutable
class ComidaItem {
  final String id;
  final String titulo;
  final String? tipoComida; // Ej: 'DESAYUNO', 'ALMUERZO', 'CENA', 'SNACK'
  final String? descripcion; // Ej: 'Scramble de huevos, bacon, café'
  final List<ComidaIngrediente> ingredientes;
  final int? _caloriasBase;
  final int? metaCalorias; // Ej: 300 kcal
  final double? _proteinasBase;
  final double? _grasasBase;
  final double? _carbohidratosBase;
  final int? healthScore; // 0 to 100 when evaluated, null when unscored
  final String? explicacionHealthScore;
  final bool healthScoreDesactualizado;
  final String hora;
  final IconData icono;

  const ComidaItem({
    required this.id,
    required this.titulo,
    this.tipoComida,
    this.descripcion,
    this.ingredientes = const [],
    int? calorias,
    this.metaCalorias,
    double? proteinas,
    double? grasas,
    double? carbohidratos,
    this.healthScore,
    this.explicacionHealthScore,
    this.healthScoreDesactualizado = false,
    required this.hora,
    this.icono = Icons.restaurant_outlined,
  }) : _caloriasBase = calorias,
       _proteinasBase = proteinas,
       _grasasBase = grasas,
       _carbohidratosBase = carbohidratos;

  bool get tieneHealthScore => healthScore != null;

  bool get tieneExplicacionHealthScore =>
      explicacionHealthScore != null &&
      explicacionHealthScore!.trim().isNotEmpty;

  /// Si tiene ingredientes desglosados, se suman dinámicamente; si no, se usan las calorías base.
  int get calorias {
    if (ingredientes.isNotEmpty) {
      return ingredientes.fold(0, (acc, i) => acc + i.calorias);
    }
    return _caloriasBase ?? 0;
  }

  double get proteinas {
    if (ingredientes.isNotEmpty) {
      final total = ingredientes.fold(0.0, (acc, i) => acc + i.proteinas);
      return double.parse(total.toStringAsFixed(1));
    }
    return _proteinasBase ?? 0.0;
  }

  double get grasas {
    if (ingredientes.isNotEmpty) {
      final total = ingredientes.fold(0.0, (acc, i) => acc + i.grasas);
      return double.parse(total.toStringAsFixed(1));
    }
    return _grasasBase ?? 0.0;
  }

  double get carbohidratos {
    if (ingredientes.isNotEmpty) {
      final total = ingredientes.fold(0.0, (acc, i) => acc + i.carbohidratos);
      return double.parse(total.toStringAsFixed(1));
    }
    return _carbohidratosBase ?? 0.0;
  }

  /// Formato de tipo de comida (ej: 'Comida', 'Desayuno')
  String get encabezadoTipo {
    final valor = (tipoComida != null && tipoComida!.trim().isNotEmpty)
        ? tipoComida!.trim()
        : (titulo.trim().isNotEmpty ? titulo.trim() : 'Comida');
    if (valor.isEmpty) return 'Comida';
    return valor[0].toUpperCase() + valor.substring(1).toLowerCase();
  }

  /// Subtítulo con el detalle de alimentos o lista de ingredientes con sus porciones
  String get detalleComida {
    if (ingredientes.isNotEmpty) {
      return ingredientes
          .map((i) => '${i.nombre} (${i.porcionLabel})')
          .join(', ');
    }
    return (descripcion != null && descripcion!.trim().isNotEmpty)
        ? descripcion!.trim()
        : titulo;
  }

  ComidaItem conIngredienteActualizado(ComidaIngrediente ingrediente) {
    final nuevaLista = ingredientes.map((i) {
      return i.id == ingrediente.id ? ingrediente : i;
    }).toList();
    return copyWith(ingredientes: nuevaLista);
  }

  ComidaItem conIngredienteAgregado(ComidaIngrediente nuevo) {
    return copyWith(ingredientes: [...ingredientes, nuevo]);
  }

  ComidaItem conIngredienteEliminado(String ingredienteId) {
    return copyWith(
      ingredientes: ingredientes.where((i) => i.id != ingredienteId).toList(),
    );
  }

  ComidaItem copyWith({
    String? id,
    String? titulo,
    String? tipoComida,
    String? descripcion,
    List<ComidaIngrediente>? ingredientes,
    int? calorias,
    int? metaCalorias,
    double? proteinas,
    double? grasas,
    double? carbohidratos,
    int? healthScore,
    bool clearHealthScore = false,
    String? explicacionHealthScore,
    bool clearExplicacionHealthScore = false,
    bool? healthScoreDesactualizado,
    String? hora,
    IconData? icono,
  }) {
    return ComidaItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipoComida: tipoComida ?? this.tipoComida,
      descripcion: descripcion ?? this.descripcion,
      ingredientes: ingredientes ?? this.ingredientes,
      calorias: calorias ?? _caloriasBase,
      metaCalorias: metaCalorias ?? this.metaCalorias,
      proteinas: proteinas ?? _proteinasBase,
      grasas: grasas ?? _grasasBase,
      carbohidratos: carbohidratos ?? _carbohidratosBase,
      healthScore: clearHealthScore ? null : (healthScore ?? this.healthScore),
      explicacionHealthScore: clearExplicacionHealthScore
          ? null
          : (explicacionHealthScore ?? this.explicacionHealthScore),
      healthScoreDesactualizado:
          healthScoreDesactualizado ?? this.healthScoreDesactualizado,
      hora: hora ?? this.hora,
      icono: icono ?? this.icono,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'tipoComida': tipoComida,
    'descripcion': descripcion,
    'calorias': _caloriasBase,
    'metaCalorias': metaCalorias,
    'proteinas': _proteinasBase,
    'grasas': _grasasBase,
    'carbohidratos': _carbohidratosBase,
    'healthScore': healthScore,
    'explicacionHealthScore': explicacionHealthScore,
    'healthScoreDesactualizado': healthScoreDesactualizado,
    'hora': hora,
    'iconoName': _iconoName,
    'ingredientes': ingredientes.map((i) => i.toJson()).toList(),
  };

  String get _iconoName {
    if (icono == Icons.coffee_outlined) return 'coffee';
    if (icono == Icons.egg_outlined) return 'egg';
    if (icono == Icons.bakery_dining_outlined) return 'bakery';
    if (icono == Icons.dinner_dining_outlined) return 'dinner';
    if (icono == Icons.lunch_dining_outlined) return 'lunch';
    if (icono == Icons.ramen_dining_outlined) return 'ramen';
    if (icono == Icons.rice_bowl_outlined) return 'bowl';
    if (icono == Icons.local_drink_outlined) return 'drink';
    if (icono == Icons.fastfood_outlined) return 'fastfood';
    return 'restaurant';
  }

  static IconData _resolverIcono(String? name) {
    switch (name) {
      case 'coffee':
        return Icons.coffee_outlined;
      case 'egg':
        return Icons.egg_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'ramen':
        return Icons.ramen_dining_outlined;
      case 'bowl':
        return Icons.rice_bowl_outlined;
      case 'drink':
        return Icons.local_drink_outlined;
      case 'fastfood':
        return Icons.fastfood_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  factory ComidaItem.fromJson(Map<String, dynamic> json) {
    final rawIngredientes = json['ingredientes'] as List<dynamic>? ?? [];
    final rawScore = json['healthScore'];
    final int? parsedScore = (rawScore is num && rawScore.isFinite)
        ? rawScore.round().clamp(0, 100)
        : null;
    final rawExplanation = json['explicacionHealthScore'];
    final String? parsedExplanation =
        (rawExplanation is String && rawExplanation.trim().isNotEmpty)
        ? rawExplanation.trim()
        : null;
    final bool isStale = json['healthScoreDesactualizado'] as bool? ?? false;

    return ComidaItem(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipoComida: json['tipoComida'] as String?,
      descripcion: json['descripcion'] as String?,
      calorias: (json['calorias'] as num?)?.toInt(),
      metaCalorias: (json['metaCalorias'] as num?)?.toInt(),
      proteinas: (json['proteinas'] as num?)?.toDouble(),
      grasas: (json['grasas'] as num?)?.toDouble(),
      carbohidratos: (json['carbohidratos'] as num?)?.toDouble(),
      healthScore: parsedScore,
      explicacionHealthScore: parsedExplanation,
      healthScoreDesactualizado: isStale,
      hora: json['hora'] as String? ?? '12:00',
      icono: _resolverIcono(json['iconoName'] as String?),
      ingredientes: rawIngredientes
          .whereType<Map<String, dynamic>>()
          .map(ComidaIngrediente.fromJson)
          .toList(),
    );
  }
}
