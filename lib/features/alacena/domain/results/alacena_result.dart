import 'package:flutter/foundation.dart';

@immutable
sealed class AlacenaResult<T> {
  const AlacenaResult();
}

class AlacenaExito<T> extends AlacenaResult<T> {
  final T datos;
  const AlacenaExito(this.datos);
}

enum AlacenaErrorCode {
  none,
  emptyName,
  invalidCategory,
  nonPositiveGrams,
  negativeCalories,
  negativeMacros,
  notFound,
}

class AlacenaFallo<T> extends AlacenaResult<T> {
  final String mensaje;
  final AlacenaErrorCode code;
  const AlacenaFallo(this.mensaje, {this.code = AlacenaErrorCode.none});
}
