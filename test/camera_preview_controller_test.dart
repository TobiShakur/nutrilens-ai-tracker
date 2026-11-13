import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/scanner/data/services/camera_preview_controller_impl.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/camera_preview_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraPreviewControllerImpl lifecycle safety', () {
    test(
      'starts uninitialized, falls back to unavailable when camera plugin is absent, and disposes safely',
      () async {
        final controller = CameraPreviewControllerImpl();

        expect(controller.status, CameraPreviewStatus.uninitialized);
        expect(controller.isReady, isFalse);
        expect(controller.activeController, isNull);
        expect(await controller.takePicture(), isNull);

        // Without registered camera platform plugin, initialize sets unavailable instead of throwing.
        await controller.initialize();
        expect(controller.status, CameraPreviewStatus.unavailable);
        expect(controller.isReady, isFalse);
        expect(controller.activeController, isNull);

        await controller.pauseAndDispose();
        expect(controller.status, CameraPreviewStatus.uninitialized);
        expect(controller.activeController, isNull);

        controller.dispose();
        expect(controller.status, CameraPreviewStatus.disposed);

        // Calls after dispose must be safe no-ops.
        await controller.resume();
        await controller.toggleFlash();
        expect(await controller.takePicture(), isNull);
      },
    );
  });
}
