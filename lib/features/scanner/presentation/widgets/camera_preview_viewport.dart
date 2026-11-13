import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/camera_preview_controller_impl.dart';
import '../../domain/services/camera_preview_controller.dart';

/// Renders the live camera stream from [CameraPreviewController] or the
/// accessible no-camera / web fallback card without leaking `package:camera`
/// into [ScannerScreen].
class CameraPreviewViewport extends StatelessWidget {
  final CameraPreviewController controller;

  const CameraPreviewViewport({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isReady) {
          final impl = controller;
          if (impl is CameraPreviewControllerImpl) {
            final active = impl.activeController;
            if (active != null && active.value.isInitialized) {
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: active.value.previewSize?.width ?? 1280,
                  height: active.value.previewSize?.height ?? 720,
                  child: CameraPreview(active),
                ),
              );
            }
          }
          // Non-hardware controller override (e.g. widget tests).
          return const ColoredBox(
            key: ValueKey('camera_preview_active'),
            color: AppColors.scannerSurfaceDark,
          );
        }

        return const _NoCameraFallbackView();
      },
    );
  }
}

class _NoCameraFallbackView extends StatelessWidget {
  const _NoCameraFallbackView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scannerSurfaceDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.pistachio.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.pistachio,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cámara en vivo no disponible',
                textAlign: TextAlign.center,
                style: AppTextStyles.title(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Usá la cámara del dispositivo, elegí de tu fototeca o armá tu comida manual.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  size: 12.5,
                  color: AppColors.textMutedLight,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
