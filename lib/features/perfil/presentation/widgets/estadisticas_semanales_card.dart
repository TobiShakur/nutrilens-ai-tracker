import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/resumen_semanal_metricas.dart';

class EstadisticasSemanalesCard extends StatelessWidget {
  final ResumenSemanalMetricas? metricas;
  final int offset;
  final ValueChanged<int> onCambiarSemana;

  const EstadisticasSemanalesCard({
    super.key,
    required this.metricas,
    required this.offset,
    required this.onCambiarSemana,
  });

  @override
  Widget build(BuildContext context) {
    final topProteina = metricas?.topProteina;
    final topCarbos = metricas?.topCarbos;
    final topGrasas = metricas?.topGrasas;
    final bool hayTop =
        topProteina != null || topCarbos != null || topGrasas != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10261D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E3A2F), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector de semana (Lunes a Domingo con navegación histórica)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onCambiarSemana(offset - 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A382B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      metricas != null
                          ? localizedWeekTitle(metricas!, context.l10n)
                          : context.l10n.statsThisWeekFallback,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title(
                        size: 13,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.statsWeekMonToSun,
                      style: AppTextStyles.body(
                        size: 10.5,
                        color: AppColors.pistachio,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: offset < 0 ? () => onCambiarSemana(offset + 1) : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: offset < 0
                        ? const Color(0xFF1A382B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: offset < 0 ? Colors.white12 : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: offset < 0 ? Colors.white : Colors.white24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Fila de KPIs de la Semana: Racha, Cumplimiento y Health Score
          Row(
            children: [
              _buildKpiBox(
                emoji: '🔥',
                titulo: context.l10n.statsStreakTitle,
                valor: context.l10n.statsStreakDays(
                  metricas?.rachaActualDias ?? 0,
                ),
                color: const Color(0xFFFF8A65),
              ),
              const SizedBox(width: 8),
              _buildKpiBox(
                emoji: '🎯',
                titulo: context.l10n.statsComplianceTitle,
                valor: metricas != null
                    ? '${(metricas!.porcentajeCumplimiento * 100).round()}%'
                    : '0%',
                color: AppColors.pistachio,
              ),
              const SizedBox(width: 8),
              _buildKpiBox(
                emoji: '⭐',
                titulo: context.l10n.healthScoreTitle,
                valor: '${metricas?.healthScorePromedio ?? 0}/100',
                color: const Color(0xFFFFD54F),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Fila de Aprovechamiento de Alacena en la semana
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF173024),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  size: 16,
                  color: AppColors.pistachio,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.statsPantryUsageTitle,
                    style: AppTextStyles.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  context.l10n.statsPantryUsagePct(
                    ((metricas?.ratioAprovechamientoAlacena ?? 0.0) * 100)
                        .round(),
                  ),
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: AppColors.pistachio,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // 4. Sección de Top Alimentos por Macro de la Semana
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.pistachio.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.pistachio,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.statsTopFoodsTitle,
                style: AppTextStyles.title(
                  size: 12,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hayTop)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                context.l10n.statsNoMealsPeriod,
                style: AppTextStyles.body(size: 11.5, color: Colors.white54),
              ),
            )
          else ...[
            if (topProteina != null)
              _buildFilaTop(
                badgeLabel: context.l10n.macroProteinUpper,
                badgeColor: const Color(0xFFE57373),
                item: topProteina,
              ),
            if (topCarbos != null) ...[
              const SizedBox(height: 8),
              _buildFilaTop(
                badgeLabel: context.l10n.macroCarbsUpper,
                badgeColor: const Color(0xFFFFB74D),
                item: topCarbos,
              ),
            ],
            if (topGrasas != null) ...[
              const SizedBox(height: 8),
              _buildFilaTop(
                badgeLabel: context.l10n.macroFatUpper,
                badgeColor: const Color(0xFF81C784),
                item: topGrasas,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildKpiBox({
    required String emoji,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF173024),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: AppTextStyles.number(
                size: 13.5,
                weight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTop({
    required String badgeLabel,
    required Color badgeColor,
    required TopIngredienteMacro item,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF173024),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  item.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.aporteMacroGramos.round()}g',
            style: AppTextStyles.number(
              size: 12.5,
              weight: FontWeight.w800,
              color: AppColors.pistachio,
            ),
          ),
        ],
      ),
    );
  }
}
