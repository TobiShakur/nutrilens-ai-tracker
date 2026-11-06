import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/configuracion_nutricional.dart';

class MetasNutricionalesCard extends StatelessWidget {
  final ConfiguracionNutricional config;
  final VoidCallback onEditar;

  const MetasNutricionalesCard({
    super.key,
    required this.config,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header con botón de modificar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.pistachio.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.pistachio,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'METAS DIARIAS',
                    style: AppTextStyles.title(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditar,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A382B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.pistachio.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: AppColors.pistachio,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Modificar',
                        style: AppTextStyles.body(
                          size: 11,
                          weight: FontWeight.w800,
                          color: AppColors.pistachio,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total de calorías objetivo
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${config.metaCalorias}',
                style: AppTextStyles.number(
                  size: 32,
                  weight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kcal / día',
                style: AppTextStyles.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Desglose de los 3 macronutrientes
          Row(
            children: [
              _buildMacroItem(
                label: 'Proteínas',
                valor: '${config.metaProteinas.round()}g',
                color: const Color(0xFFE57373),
              ),
              const SizedBox(width: 8),
              _buildMacroItem(
                label: 'Carbos',
                valor: '${config.metaCarbos.round()}g',
                color: const Color(0xFFFFB74D),
              ),
              const SizedBox(width: 8),
              _buildMacroItem(
                label: 'Grasas',
                valor: '${config.metaGrasas.round()}g',
                color: const Color(0xFF81C784),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required String valor,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: AppTextStyles.number(
                size: 14,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
