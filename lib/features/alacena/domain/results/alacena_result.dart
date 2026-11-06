import 'package:flutter/foundation.dart';

@immutable
sealed class AlacenaResult<T> {
  const AlacenaResult();
}

class AlacenaExito<T> extends AlacenaResult<T> {
  final T datos;
  const AlacenaExito(this.datos);
}

class AlacenaFallo<T> extends AlacenaResult<T> {
  final String mensaje;
  const AlacenaFallo(this.mensaje);
}
