import 'package:flutter/foundation.dart';

/// Chip de muestra para probar el escáner por código de barras sin cámara física.
@immutable
class BarcodeDemoChip {
  final String label;
  final String codigo;

  const BarcodeDemoChip({required this.label, required this.codigo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeDemoChip &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          codigo == other.codigo;

  @override
  int get hashCode => Object.hash(label, codigo);
}
