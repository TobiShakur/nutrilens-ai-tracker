import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Wrapper adaptativo:
/// - En celulares y pantallas chicas (< 600px): ocupa el 100% de la pantalla nativa sin bordes ni márgenes negros.
/// - En monitores de escritorio (>= 600px): presenta el frame móvil centrado con sombra.
class DesktopWrapper extends StatelessWidget {
  final Widget child;

  const DesktopWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileViewport = constraints.maxWidth < 600;

        if (isMobileViewport) {
          return Material(
            color: AppColors.scaffoldBg,
            textStyle: AppTextStyles.body(),
            child: SizedBox.expand(child: child),
          );
        }

        return Material(
          color: AppColors.webBg,
          textStyle: AppTextStyles.body(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 395, maxHeight: 730),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.pistachio.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
