import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/log_sanitizer.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/services/camera_preview_controller.dart';

/// Hardware implementation of [CameraPreviewController] wrapping `package:camera`.
///
/// Nullifies [_controller] before calling `dispose()` and guards async
/// initialization races with [_lifecycleEpoch] so Android resume/pause events
/// never expose a disposed controller to widget `build()`.
class CameraPreviewControllerImpl extends ChangeNotifier
    implements CameraPreviewController {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  CameraPreviewStatus _status = CameraPreviewStatus.uninitialized;
  bool _flashOn = false;
  bool _disposed = false;
  int _lifecycleEpoch = 0;

  /// Exposed exclusively to [CameraPreviewViewport] in the presentation widget layer.
  CameraController? get activeController => _controller;

  @override
  CameraPreviewStatus get status => _status;

  @override
  bool get isReady =>
      !_disposed &&
      _status == CameraPreviewStatus.ready &&
      _controller != null &&
      _controller!.value.isInitialized;

  @override
  bool get isFlashOn => _flashOn;

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    final epoch = ++_lifecycleEpoch;

    try {
      final cameras = await availableCameras();
      if (_disposed || epoch != _lifecycleEpoch) return;

      if (cameras.isEmpty) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
        return;
      }

      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex != -1 ? backIndex : 0;

      await _configureController(cameras[_selectedCameraIndex], epoch);
    } on CameraException catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Camera unavailable during discovery: ${e.code}',
      );
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    } on PlatformException catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Platform camera error: ${e.code}',
      );
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    } catch (_) {
      // Fallback transparently to native picker / manual flow on web or unsupported platforms.
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    }
  }

  Future<void> _configureController(
    CameraDescription description,
    int epoch,
  ) async {
    final prev = _controller;
    _controller = null;
    _flashOn = false;
    if (prev != null) {
      await _safeDisposeController(prev);
    }
    if (_disposed || epoch != _lifecycleEpoch) return;

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (_disposed || epoch != _lifecycleEpoch) {
        await _safeDisposeController(controller);
        return;
      }

      _controller = controller;
      _status = CameraPreviewStatus.ready;
      _notifySafe();
    } on CameraException catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Camera initialize failed: ${e.code}',
      );
      await _safeDisposeController(controller);
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    } on PlatformException catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Platform initialize failed: ${e.code}',
      );
      await _safeDisposeController(controller);
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    } catch (_) {
      await _safeDisposeController(controller);
      if (!_disposed && epoch == _lifecycleEpoch) {
        _status = CameraPreviewStatus.unavailable;
        _notifySafe();
      }
    }
  }

  @override
  Future<void> pauseAndDispose() async {
    _lifecycleEpoch++;
    final prev = _controller;
    _controller = null;
    _flashOn = false;

    if (!_disposed && _status != CameraPreviewStatus.disposed) {
      _status = CameraPreviewStatus.uninitialized;
      _notifySafe();
    }

    if (prev != null) {
      await _safeDisposeController(prev);
    }
  }

  @override
  Future<void> resume() async {
    if (_disposed || _controller != null) return;
    if (_cameras.isNotEmpty) {
      final epoch = ++_lifecycleEpoch;
      await _configureController(_cameras[_selectedCameraIndex], epoch);
    } else {
      await initialize();
    }
  }

  @override
  Future<void> toggleFlash() async {
    final controller = _controller;
    if (_disposed || controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextFlash = !_flashOn;
    try {
      await controller.setFlashMode(
        nextFlash ? FlashMode.torch : FlashMode.off,
      );
      if (!_disposed && _controller == controller) {
        _flashOn = nextFlash;
        _notifySafe();
      }
    } catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Flash toggle failed (${e.runtimeType})',
      );
    }
  }

  @override
  Future<ImagenPlato?> takePicture() async {
    final controller = _controller;
    if (_disposed || controller == null || !controller.value.isInitialized) {
      return null;
    }

    try {
      final xfile = await controller.takePicture();
      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return null;

      return ImagenPlato.crear(
        bytes: bytes,
        nombreArchivo: xfile.name,
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      LogSanitizer.logDebug(
        'CameraPreview',
        'Live capture failed (${e.runtimeType})',
      );
      return null;
    }
  }

  Future<void> _safeDisposeController(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // Ignore disposal errors from an already released native camera session.
    }
  }

  void _notifySafe() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _status = CameraPreviewStatus.disposed;
    _lifecycleEpoch++;
    final prev = _controller;
    _controller = null;
    if (prev != null) {
      _safeDisposeController(prev);
    }
    super.dispose();
  }
}
