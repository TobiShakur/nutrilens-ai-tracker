// SERVICIO DE CAPTURA Y COMPRESIÓN DE IMÁGENES
// Accede a la cámara o galería nativa aplicando compresión de imagen previa (1024px @ 80%)
// para reducir la latencia de red y el consumo de ancho de banda en la inferencia multimodal.

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/log_sanitizer.dart';
import '../../../alacena/domain/failures/barcode_scan_failure.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/services/image_capture_service.dart';

/// Implementación de producción para captura de fotos usando el plugin oficial image_picker.
class ImagePickerCaptureServiceImpl implements ImageCaptureService {
  final ImagePicker _picker;

  ImagePickerCaptureServiceImpl({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<ImagenPlato?> capturarConCamara() =>
      _capturar(source: ImageSource.camera, esCamara: true);

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() =>
      _capturar(source: ImageSource.gallery, esCamara: false);

  Future<ImagenPlato?> _capturar({
    required ImageSource source,
    required bool esCamara,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file == null) return null;
      return _procesarArchivo(file);
    } on PlatformException catch (e) {
      LogSanitizer.logDebug(
        'ImageCapture',
        'PlatformException (${esCamara ? 'cámara' : 'galería'}) code=${e.code}',
      );
      if (_esErrorPermiso(e.code)) {
        throw BarcodePermisoDenegadoFailure(esCamara: esCamara);
      }
      rethrow;
    } catch (e) {
      LogSanitizer.logDebug(
        'ImageCapture',
        'Error al capturar (${esCamara ? 'cámara' : 'galería'}): $e',
      );
      rethrow;
    }
  }

  bool _esErrorPermiso(String code) {
    final normalized = code.toLowerCase();
    return normalized == 'camera_access_denied' ||
        normalized == 'photo_access_denied' ||
        normalized.contains('access_denied') ||
        normalized.contains('permission');
  }

  Future<ImagenPlato?> _procesarArchivo(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final mime = file.mimeType ?? _inferirMime(file.name);
    return ImagenPlato.crear(
      bytes: bytes,
      mimeType: mime,
      nombreArchivo: file.name,
    );
  }

  String _inferirMime(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
