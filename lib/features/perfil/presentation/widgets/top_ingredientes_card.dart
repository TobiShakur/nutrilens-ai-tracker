import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/resumen_semanal_metricas.dart';

class TopIngredientesCard extends StatelessWidget {
  final TopIngredienteMacro? topProteina;
  final TopIngredienteMacro? topCarbos;
  final TopIngredienteMacro? topGrasas;

  const TopIngredientesCard({
    super.key,
    required this.topProteina,
    required this.topCarbos,
    required this.topGrasas,
  });

  @override
  Widget build(BuildContext context) {
    final hayDatos =
        topProteina != null || topCarbos != null || topGrasas != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.forestDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.forestDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.statsTopFoodsTitle,
                      style: AppTextStyles.title(
                        size: 13,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.l10n.statsTopFoodsSubtitle,
                      style: AppTextStyles.body(
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hayDatos)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                context.l10n.statsNoMealsWeek,
                style: AppTextStyles.body(size: 12, color: AppColors.textMuted),
              ),
            )
          else ...[
            if (topProteina != null)
              _buildFilaTop(
                context,
                badgeLabel: context.l10n.macroProteinUpper,
                badgeColor: const Color(0xFFE57373),
                item: topProteina!,
              ),
            if (topCarbos != null) ...[
              const SizedBox(height: 10),
              _buildFilaTop(
                context,
                badgeLabel: context.l10n.macroCarbsUpper,
                badgeColor: const Color(0xFFFFB74D),
                item: topCarbos!,
              ),
            ],
            if (topGrasas != null) ...[
              const SizedBox(height: 10),
              _buildFilaTop(
                context,
                badgeLabel: context.l10n.macroHealthyFatUpper,
                badgeColor: const Color(0xFF81C784),
                item: topGrasas!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFilaTop(
    BuildContext context, {
    required String badgeLabel,
    required Color badgeColor,
    required TopIngredienteMacro item,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          size: 13,
                          weight: FontWeight.w800,
                          color: AppColors.forestDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.statsTopContribution(
                    item.aporteMacroGramos.toStringAsFixed(1),
                    item.vecesConsumido,
                  ),
                  style: AppTextStyles.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
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
