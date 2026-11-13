import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Fila de 3 Píldoras de Macronutrientes (Proteínas, Grasas, Carbos)
class MacroRowWidget extends StatelessWidget {
  final double proteinasConsumidas;
  final double metaProteinas;
  final double grasasConsumidas;
  final double metaGrasas;
  final double carbosConsumidos;
  final double metaCarbos;

  const MacroRowWidget({
    super.key,
    required this.proteinasConsumidas,
    required this.metaProteinas,
    required this.grasasConsumidas,
    required this.metaGrasas,
    required this.carbosConsumidos,
    required this.metaCarbos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            label: l10n.macroProtein,
            consumed: proteinasConsumidas,
            target: metaProteinas,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: l10n.macroFat,
            consumed: grasasConsumidas,
            target: metaGrasas,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: l10n.macroCarbs,
            consumed: carbosConsumidos,
            target: metaCarbos,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required double consumed,
    required double target,
  }) {
    final double ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E3827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${consumed.round()}',
                  style: AppTextStyles.number(
                    size: 21,
                    weight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  ' /${target.round()} g',
                  style: const TextStyle(
                    color: AppColors.textMutedLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Mini Barra de Progreso Pistacho redondeada
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.forestSlot,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.pistachio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
