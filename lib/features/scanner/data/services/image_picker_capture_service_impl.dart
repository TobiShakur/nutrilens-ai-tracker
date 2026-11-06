// SERVICIO DE CAPTURA Y COMPRESIÓN DE IMÁGENES
// Accede a la cámara o galería nativa aplicando compresión de imagen previa (1024px @ 80%)
// para reducir la latencia de red y el consumo de ancho de banda en la inferencia multimodal.

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/services/image_capture_service.dart';

/// Implementación de producción para captura de fotos usando el plugin oficial image_picker.
class ImagePickerCaptureServiceImpl implements ImageCaptureService {
  final ImagePicker _picker;

  ImagePickerCaptureServiceImpl({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<ImagenPlato?> capturarConCamara() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file == null) return null;
      return _procesarArchivo(file);
    } catch (e) {
      debugPrint('Error al capturar foto con cámara: $e');
      return null;
    }
  }

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file == null) return null;
      return _procesarArchivo(file);
    } catch (e) {
      debugPrint('Error al seleccionar imagen de galería: $e');
      return null;
    }
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
    return 'image/jpeg';
  }
}
