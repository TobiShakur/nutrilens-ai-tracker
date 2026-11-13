import 'package:flutter/foundation.dart';
import '../../../scanner/domain/entities/imagen_plato.dart';
import '../../../scanner/domain/services/image_capture_service.dart';
import '../../domain/datasources/barcode_demo_datasource.dart';
import '../../domain/entities/barcode_demo_chip.dart';
import '../../domain/entities/barcode_validator.dart';
import '../../domain/failures/barcode_scan_failure.dart';
import '../../domain/services/barcode_product_service.dart';
import 'barcode_scanner_state.dart';

/// ViewModel puro (Dart sin UI) que gobierna el escáner de productos y etiquetas.
class BarcodeScannerViewModel extends ChangeNotifier {
  final BarcodeProductService barcodeService;
  final ImageCaptureService imageCaptureService;

  ModoEscaneoProducto _modo = ModoEscaneoProducto.camara;
  BarcodeScannerState _state = const BarcodeScannerIdle();
  late final List<BarcodeDemoChip> _chipsDemo;
  bool _disposed = false;

  BarcodeScannerViewModel({
    required this.barcodeService,
    required this.imageCaptureService,
    required BarcodeDemoDatasource demoDatasource,
  }) {
    _chipsDemo = List.unmodifiable(demoDatasource.obtenerChipsDemostracion());
  }

  ModoEscaneoProducto get modo => _modo;
  BarcodeScannerState get state => _state;
  List<BarcodeDemoChip> get chipsDemo => _chipsDemo;
  bool get estaCargando => _state is BarcodeScannerLoading;

  void cambiarModo(ModoEscaneoProducto nuevoModo) {
    if (_modo == nuevoModo || _state is BarcodeScannerLoading || _disposed) {
      return;
    }
    _modo = nuevoModo;
    if (_state is BarcodeScannerError) {
      _state = const BarcodeScannerIdle();
    }
    _notificarSeguro();
  }

  Future<void> capturarConCamara({String languageCode = 'es'}) =>
      _ejecutarCapturaImagen(
        imageCaptureService.capturarConCamara,
        languageCode: languageCode,
      );

  Future<void> seleccionarDeGaleria({String languageCode = 'es'}) =>
      _ejecutarCapturaImagen(
        imageCaptureService.seleccionarDeGaleria,
        languageCode: languageCode,
      );

  Future<void> _ejecutarCapturaImagen(
    Future<ImagenPlato?> Function() selector, {
    String languageCode = 'es',
  }) async {
    // Guardia anti doble-tap antes del primer await.
    if (_state is BarcodeScannerLoading || _disposed) return;

    _state = const BarcodeScannerLoading(
      mensaje: 'Abriendo...',
      step: BarcodeLoadingStep.openingPicker,
    );
    _notificarSeguro();

    try {
      final imagen = await selector();
      if (_disposed) return;

      if (imagen == null) {
        _state = const BarcodeScannerIdle();
        _notificarSeguro();
        return;
      }

      final errorImagen = BarcodeValidator.validarImagenEtiqueta(
        imagen.bytes,
        imagen.mimeType,
      );
      if (errorImagen != null) {
        _state = _mapearFallo(BarcodeImagenInvalidaFailure(errorImagen));
        _notificarSeguro();
        return;
      }

      _state = const BarcodeScannerLoading(
        mensaje: 'Analizando producto...',
        step: BarcodeLoadingStep.analyzingLabel,
      );
      _notificarSeguro();

      final producto = await barcodeService.analizarFotoEtiqueta(
        bytes: imagen.bytes,
        mimeType: imagen.mimeType,
        languageCode: languageCode,
      );
      if (_disposed) return;

      if (producto == null) {
        _state = const BarcodeScannerError(
          mensaje:
              'No se pudo detectar un producto legible. Probá enfocando mejor la tabla nutricional o el código.',
          tipo: BarcodeErrorTipo.noEncontrado,
          code: BarcodeErrorCode.labelNotFound,
        );
      } else {
        _state = BarcodeScannerSuccess(producto: producto);
      }
      _notificarSeguro();
    } on BarcodeScanFailure catch (failure) {
      if (_disposed) return;
      _state = _mapearFallo(failure);
      _notificarSeguro();
    } catch (_) {
      if (_disposed) return;
      _state = const BarcodeScannerError(
        mensaje: 'No se pudo procesar la imagen. Intentá nuevamente.',
        tipo: BarcodeErrorTipo.desconocido,
        code: BarcodeErrorCode.unknown,
      );
      _notificarSeguro();
    }
  }

  Future<void> buscarPorCodigoBarras(
    String codigoRaw, {
    String languageCode = 'es',
  }) async {
    if (_state is BarcodeScannerLoading || _disposed) return;

    final limpio = BarcodeValidator.limpiar(codigoRaw);
    if (limpio.isEmpty) {
      _state = const BarcodeScannerError(
        mensaje: 'Ingresá los números del código de barras.',
        tipo: BarcodeErrorTipo.codigoInvalido,
        code: BarcodeErrorCode.missingBarcode,
      );
      _notificarSeguro();
      return;
    }

    if (!BarcodeValidator.esCodigoValido(limpio)) {
      _state = const BarcodeScannerError(
        mensaje: 'El código de barras ingresado no es válido.',
        tipo: BarcodeErrorTipo.codigoInvalido,
        code: BarcodeErrorCode.invalidBarcode,
      );
      _notificarSeguro();
      return;
    }

    _state = const BarcodeScannerLoading(
      mensaje: 'Buscando producto...',
      step: BarcodeLoadingStep.lookingUpBarcode,
    );
    _notificarSeguro();

    try {
      final data = await barcodeService.buscarPorCodigoBarras(
        limpio,
        languageCode: languageCode,
      );
      if (_disposed) return;

      if (data == null) {
        _state = BarcodeScannerError(
          mensaje:
              'No encontramos el producto con código $limpio en la base de datos.',
          tipo: BarcodeErrorTipo.noEncontrado,
          code: BarcodeErrorCode.productNotFound,
          barcode: limpio,
        );
      } else {
        _state = BarcodeScannerSuccess(producto: data);
      }
      _notificarSeguro();
    } on BarcodeScanFailure catch (failure) {
      if (_disposed) return;
      _state = _mapearFallo(failure);
      _notificarSeguro();
    } catch (_) {
      if (_disposed) return;
      _state = const BarcodeScannerError(
        mensaje: 'No se pudo consultar el producto. Intentá nuevamente.',
        tipo: BarcodeErrorTipo.desconocido,
        code: BarcodeErrorCode.unknown,
      );
      _notificarSeguro();
    }
  }

  void reiniciarEscaneo() {
    if (_state is BarcodeScannerIdle ||
        _state is BarcodeScannerLoading ||
        _disposed) {
      return;
    }
    _state = const BarcodeScannerIdle();
    _notificarSeguro();
  }

  BarcodeScannerError _mapearFallo(BarcodeScanFailure failure) {
    return switch (failure) {
      BarcodeApiKeyFaltanteFailure() => const BarcodeScannerError(
        mensaje:
            'La función con IA requiere configurar GEMINI_API_KEY en este entorno.',
        tipo: BarcodeErrorTipo.sinApiKey,
        code: BarcodeErrorCode.missingApiKey,
      ),
      BarcodeCodigoInvalidoFailure() => const BarcodeScannerError(
        mensaje: 'El código de barras ingresado no es válido.',
        tipo: BarcodeErrorTipo.codigoInvalido,
        code: BarcodeErrorCode.invalidBarcode,
      ),
      BarcodeImagenInvalidaFailure(:final razon) => BarcodeScannerError(
        mensaje: switch (razon) {
          'vacia' => 'La imagen seleccionada está vacía.',
          'tamano_excedido' => 'La imagen supera el máximo permitido de 10 MB.',
          'mime_no_soportado' =>
            'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.',
          _ => 'La imagen seleccionada no es válida.',
        },
        tipo: BarcodeErrorTipo.imagenInvalida,
        code: switch (razon) {
          'vacia' => BarcodeErrorCode.emptyImage,
          'tamano_excedido' => BarcodeErrorCode.tooLargeImage,
          'mime_no_soportado' => BarcodeErrorCode.unsupportedMime,
          _ => BarcodeErrorCode.emptyImage,
        },
      ),
      BarcodePermisoDenegadoFailure(:final esCamara) => BarcodeScannerError(
        mensaje: esCamara
            ? 'Necesitamos permiso de cámara para escanear la etiqueta.'
            : 'Necesitamos permiso de galería para elegir una foto.',
        tipo: BarcodeErrorTipo.permisoDenegado,
        code: esCamara
            ? BarcodeErrorCode.cameraPermission
            : BarcodeErrorCode.galleryPermission,
      ),
      BarcodeRedFailure() => const BarcodeScannerError(
        mensaje:
            'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.',
        tipo: BarcodeErrorTipo.red,
        code: BarcodeErrorCode.network,
      ),
      BarcodeTimeoutFailure() => const BarcodeScannerError(
        mensaje:
            'La consulta tardó demasiado. Intentá nuevamente en unos segundos.',
        tipo: BarcodeErrorTipo.timeout,
        code: BarcodeErrorCode.timeout,
      ),
      BarcodeRateLimitFailure() => const BarcodeScannerError(
        mensaje:
            'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.',
        tipo: BarcodeErrorTipo.rateLimit,
        code: BarcodeErrorCode.rateLimit,
      ),
      BarcodeApiNoDisponibleFailure() => const BarcodeScannerError(
        mensaje:
            'El servicio de productos no está disponible en este momento. Probá más tarde.',
        tipo: BarcodeErrorTipo.servicioNoDisponible,
        code: BarcodeErrorCode.serviceUnavailable,
      ),
      BarcodeRespuestaInvalidaFailure() => const BarcodeScannerError(
        mensaje:
            'No pudimos interpretar la respuesta del servicio. Intentá nuevamente.',
        tipo: BarcodeErrorTipo.desconocido,
        code: BarcodeErrorCode.invalidResponse,
      ),
    };
  }

  void _notificarSeguro() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
