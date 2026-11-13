import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/nivel_score.dart';

/// Health score del día compacto en una sola fila integrada.
class HealthScoreBanner extends StatelessWidget {
  final int healthScore;
  final NivelScore nivel;

  const HealthScoreBanner({
    super.key,
    required this.healthScore,
    required this.nivel,
  });

  Color get _color => switch (nivel) {
    NivelScore.excelente || NivelScore.bueno => AppColors.scoreGood,
    NivelScore.moderado => AppColors.scoreMid,
    NivelScore.bajo => AppColors.scoreLow,
    NivelScore.sinRegistros => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _color;
    final mensaje = switch (nivel) {
      NivelScore.excelente => l10n.healthScoreBannerExcellent,
      NivelScore.bueno => l10n.healthScoreBannerGood,
      NivelScore.moderado => l10n.healthScoreBannerModerate,
      NivelScore.bajo => l10n.healthScoreBannerLow,
      NivelScore.sinRegistros => l10n.healthScoreBannerNoRecords,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              nivel == NivelScore.sinRegistros ? '--' : '$healthScore',
              style: AppTextStyles.number(
                size: 18,
                weight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HEALTH SCORE',
                  style: AppTextStyles.title(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
