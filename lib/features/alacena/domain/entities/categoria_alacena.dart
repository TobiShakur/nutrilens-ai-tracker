import 'package:flutter/foundation.dart';

@immutable
class CategoriaAlacena {
  final String id;
  final String label;
  final String emoji;

  const CategoriaAlacena({
    required this.id,
    required this.label,
    required this.emoji,
  });

  static const todos = CategoriaAlacena(
    id: 'todos',
    label: 'Todos',
    emoji: '🏷️',
  );
  static const proteinas = CategoriaAlacena(
    id: 'proteinas',
    label: 'Proteínas',
    emoji: '🥩',
  );
  static const carbohidratos = CategoriaAlacena(
    id: 'carbohidratos',
    label: 'Carbos',
    emoji: '🍞',
  );
  static const lacteos = CategoriaAlacena(
    id: 'lacteos',
    label: 'Lácteos',
    emoji: '🧀',
  );
  static const grasas = CategoriaAlacena(
    id: 'grasas',
    label: 'Grasas',
    emoji: '🥑',
  );
  static const vegetales = CategoriaAlacena(
    id: 'vegetales',
    label: 'Verduras / Frutas',
    emoji: '🥦',
  );
  static const otros = CategoriaAlacena(
    id: 'otros',
    label: 'Otros / Especias',
    emoji: '🧂',
  );

  static List<CategoriaAlacena> get predeterminadas => const [
    todos,
    proteinas,
    carbohidratos,
    lacteos,
    grasas,
    vegetales,
    otros,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaAlacena &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
