import 'package:flutter/foundation.dart';

/// Fallos tipados de dominio para el módulo de escaneo de productos y etiquetas.
/// Ninguna subclase almacena URIs, headers, cuerpos de respuesta ni excepciones crudas.
@immutable
sealed class BarcodeScanFailure implements Exception {
  const BarcodeScanFailure();
}

final class BarcodeApiKeyFaltanteFailure extends BarcodeScanFailure {
  const BarcodeApiKeyFaltanteFailure();
}

final class BarcodeCodigoInvalidoFailure extends BarcodeScanFailure {
  const BarcodeCodigoInvalidoFailure();
}

final class BarcodeImagenInvalidaFailure extends BarcodeScanFailure {
  final String razon; // 'vacia' | 'tamano_excedido' | 'mime_no_soportado'
  const BarcodeImagenInvalidaFailure(this.razon);
}

final class BarcodePermisoDenegadoFailure extends BarcodeScanFailure {
  final bool esCamara;
  const BarcodePermisoDenegadoFailure({required this.esCamara});
}

final class BarcodeRedFailure extends BarcodeScanFailure {
  const BarcodeRedFailure();
}

final class BarcodeTimeoutFailure extends BarcodeScanFailure {
  const BarcodeTimeoutFailure();
}

final class BarcodeRateLimitFailure extends BarcodeScanFailure {
  const BarcodeRateLimitFailure();
}

final class BarcodeApiNoDisponibleFailure extends BarcodeScanFailure {
  final int? statusCode;
  const BarcodeApiNoDisponibleFailure({this.statusCode});
}

final class BarcodeRespuestaInvalidaFailure extends BarcodeScanFailure {
  const BarcodeRespuestaInvalidaFailure();
}
