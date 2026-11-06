import 'package:flutter/foundation.dart';

/// Value Object inmutable que representa una imagen capturada para análisis.
@immutable
class ImagenPlato {
  final Uint8List bytes;
  final String mimeType;
  final String? nombreArchivo;

  const ImagenPlato._({
    required this.bytes,
    required this.mimeType,
    this.nombreArchivo,
  });

  /// Factory con validaciones defensivas de dominio
  factory ImagenPlato.crear({
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
    String? nombreArchivo,
  }) {
    if (bytes.isEmpty) {
      throw ArgumentError(
        'La imagen no puede contener un buffer de bytes vacío.',
      );
    }
    // Límite de seguridad: 15 MB
    const limiteBytes = 15 * 1024 * 1024;
    if (bytes.length > limiteBytes) {
      throw ArgumentError(
        'La imagen supera el límite máximo permitido de 15 MB.',
      );
    }
    return ImagenPlato._(
      bytes: bytes,
      mimeType: mimeType,
      nombreArchivo: nombreArchivo,
    );
  }

  int get tamanoBytes => bytes.length;

  String get tamanoLegible {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
