import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shared interactive Health Score pill rendered across meal review, feed,
/// detail, and edit surfaces with a guaranteed 44x44 touch target.
class HealthScoreBadge extends StatelessWidget {
  final int? healthScore;
  final bool isStale;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onTap;
  final bool compact;

  const HealthScoreBadge({
    super.key,
    required this.healthScore,
    this.isStale = false,
    this.isLoading = false,
    this.hasError = false,
    this.onTap,
    this.compact = false,
  });

  Color _semanticDotColor(int score) {
    if (score >= 70) return AppColors.scoreGood;
    if (score >= 50) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  String _semanticsLabel() {
    if (isLoading) return 'Calculando puntaje de salud.';
    if (hasError) {
      final scoreText = healthScore != null ? '$healthScore' : '?';
      return 'Error al calcular puntaje de salud, $scoreText de 100.';
    }
    if (healthScore == null) {
      return 'Puntaje de salud sin calcular, ? de 100. Tocá para calcular con IA.';
    }
    if (isStale) {
      return 'Puntaje de salud desactualizado, $healthScore de 100. Tocá para recalcular según tus cambios.';
    }
    return 'Puntaje de salud $healthScore de 100. Tocá para ver la explicación o recalcular.';
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    final Color fillColor;
    final Color borderColor;
    final double borderWidth;
    final String contentKey;
    final Widget? leading;
    final String labelText;
    final Color labelColor;
    final Widget? trailing;

    if (isLoading) {
      contentKey = 'loading_${compact ? 'compact' : 'full'}';
      fillColor = AppColors.inputBg;
      borderColor = AppColors.borderLight;
      borderWidth = 1.0;
      leading = const SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.forestDark,
        ),
      );
      labelText = compact ? '${healthScore ?? '?'}/100' : 'Calculando';
      labelColor = AppColors.forestDark;
      trailing = null;
    } else if (hasError) {
      contentKey = 'error_${healthScore ?? 'null'}';
      fillColor = AppColors.errorTintLight;
      borderColor = AppColors.alertRed.withValues(alpha: 0.45);
      borderWidth = 1.2;
      leading = const Icon(
        Icons.error_outline_rounded,
        size: 14.5,
        color: AppColors.alertRed,
      );
      labelText = '${healthScore ?? '?'}/100';
      labelColor = AppColors.textDark;
      trailing = const Icon(
        Icons.refresh_rounded,
        size: 14.5,
        color: AppColors.alertRed,
      );
    } else if (healthScore == null) {
      contentKey = 'unscored';
      fillColor = AppColors.inputBg;
      borderColor = AppColors.forestDark.withValues(alpha: 0.28);
      borderWidth = 1.2;
      leading = null;
      labelText = '?/100';
      labelColor = AppColors.forestDark;
      trailing = const Icon(
        Icons.help_outline_rounded,
        size: 15,
        color: AppColors.forestDark,
      );
    } else if (isStale) {
      contentKey = 'stale_$healthScore';
      fillColor = AppColors.pistachioLight;
      borderColor = AppColors.pistachioDark;
      borderWidth = 1.2;
      leading = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _semanticDotColor(healthScore!).withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
      );
      labelText = '$healthScore/100';
      labelColor = AppColors.textDark;
      trailing = const Icon(
        Icons.refresh_rounded,
        size: 15,
        color: AppColors.forestDark,
      );
    } else {
      contentKey = 'fresh_$healthScore';
      fillColor = compact ? AppColors.scaffoldBg : AppColors.cardWhite;
      borderColor = AppColors.borderLight;
      borderWidth = 1.2;
      leading = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _semanticDotColor(healthScore!),
          shape: BoxShape.circle,
        ),
      );
      labelText = '$healthScore/100';
      labelColor = AppColors.textDark;
      trailing = const Icon(
        Icons.help_outline_rounded,
        size: 14.5,
        color: AppColors.textMutedAccessible,
      );
    }

    final pillHeight = compact ? 30.0 : 32.0;

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: _semanticsLabel(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: isLoading ? null : onTap,
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                height: pillHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: Row(
                    key: ValueKey(contentKey),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: 6),
                      ],
                      Text(
                        labelText,
                        style:
                            AppTextStyles.number(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: labelColor,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 4),
                        trailing,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
