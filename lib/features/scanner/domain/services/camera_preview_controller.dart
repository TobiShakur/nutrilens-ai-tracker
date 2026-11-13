import 'package:flutter/foundation.dart';
import '../entities/imagen_plato.dart';

/// Lifecycle states for the live camera preview hardware controller.
enum CameraPreviewStatus { uninitialized, ready, unavailable, disposed }

/// Pure-Dart contract abstracting live camera preview, flash, capture, and lifecycle.
abstract class CameraPreviewController implements ChangeNotifier {
  CameraPreviewStatus get status;
  bool get isReady;
  bool get isFlashOn;

  Future<void> initialize();
  Future<void> pauseAndDispose();
  Future<void> resume();
  Future<void> toggleFlash();
  Future<ImagenPlato?> takePicture();
}
