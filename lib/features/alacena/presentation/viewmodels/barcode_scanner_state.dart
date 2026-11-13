import 'package:flutter/foundation.dart';
import '../../domain/entities/barcode_product_data.dart';

/// Modos de entrada disponibles en el escáner de productos de alacena.
enum ModoEscaneoProducto { camara, codigo }

enum BarcodeLoadingStep { openingPicker, analyzingLabel, lookingUpBarcode }

enum BarcodeErrorCode {
  none,
  cameraPermission,
  galleryPermission,
  emptyImage,
  tooLargeImage,
  unsupportedMime,
  labelNotFound,
  missingBarcode,
  invalidBarcode,
  productNotFound,
  missingApiKey,
  network,
  timeout,
  rateLimit,
  serviceUnavailable,
  invalidResponse,
  unknown,
}

/// Categorías cerradas de error mostradas al usuario sin exponer detalles técnicos.
enum BarcodeErrorTipo {
  permisoDenegado,
  codigoInvalido,
  imagenInvalida,
  noEncontrado,
  sinApiKey,
  red,
  timeout,
  rateLimit,
  servicioNoDisponible,
  desconocido,
}

/// Máquina de estados inmutable para el flujo de escaneo de código de barras y etiquetas.
@immutable
sealed class BarcodeScannerState {
  const BarcodeScannerState();
}

final class BarcodeScannerIdle extends BarcodeScannerState {
  const BarcodeScannerIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BarcodeScannerIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class BarcodeScannerLoading extends BarcodeScannerState {
  final String mensaje;
  final BarcodeLoadingStep step;
  const BarcodeScannerLoading({
    required this.mensaje,
    this.step = BarcodeLoadingStep.openingPicker,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeScannerLoading &&
          mensaje == other.mensaje &&
          step == other.step;

  @override
  int get hashCode => Object.hash(runtimeType, mensaje, step);
}

final class BarcodeScannerSuccess extends BarcodeScannerState {
  final BarcodeProductData producto;
  const BarcodeScannerSuccess({required this.producto});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeScannerSuccess && producto == other.producto;

  @override
  int get hashCode => Object.hash(runtimeType, producto);
}

final class BarcodeScannerError extends BarcodeScannerState {
  final String mensaje;
  final BarcodeErrorTipo tipo;
  final BarcodeErrorCode code;
  final String? barcode;
  const BarcodeScannerError({
    required this.mensaje,
    required this.tipo,
    this.code = BarcodeErrorCode.none,
    this.barcode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeScannerError &&
          mensaje == other.mensaje &&
          tipo == other.tipo &&
          code == other.code &&
          barcode == other.barcode;

  @override
  int get hashCode => Object.hash(runtimeType, mensaje, tipo, code, barcode);
}
