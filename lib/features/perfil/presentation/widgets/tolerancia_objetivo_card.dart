import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/configuracion_nutricional.dart';

class ToleranciaObjetivoCard extends StatelessWidget {
  final ConfiguracionNutricional config;
  final void Function(double delta) onCambiarInferior;
  final void Function(double delta) onCambiarSuperior;

  const ToleranciaObjetivoCard({
    super.key,
    required this.config,
    required this.onCambiarInferior,
    required this.onCambiarSuperior,
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
                  Icons.tune_rounded,
                  color: AppColors.pistachio,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RANGO DE TOLERANCIA',
                      style: AppTextStyles.title(
                        size: 13,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Margen de éxito para completar tu racha diaria',
                      style: AppTextStyles.body(
                        size: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner de la ventana calórica resultante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF173024),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENTANA VÁLIDA',
                      style: AppTextStyles.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: AppColors.pistachio,
                      ),
                    ),
                    Text(
                      config.ventanaCaloricaLabel,
                      style: AppTextStyles.number(
                        size: 16,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10261D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.pistachio.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${config.toleranciaInferiorLabel} / ${config.toleranciaSuperiorLabel}',
                    style: const TextStyle(
                      color: AppColors.pistachio,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dos controles independientes para - y +
          Row(
            children: [
              Expanded(
                child: _buildSelectorMargen(
                  titulo: 'Límite Inferior (-)',
                  subtitulo: 'Mínimo requerido',
                  valorLabel: config.toleranciaInferiorLabel,
                  onRestar: () => onCambiarInferior(-0.02),
                  onSumar: () => onCambiarInferior(0.02),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectorMargen(
                  titulo: 'Límite Superior (+)',
                  subtitulo: 'Máximo admitido',
                  valorLabel: config.toleranciaSuperiorLabel,
                  onRestar: () => onCambiarSuperior(-0.02),
                  onSumar: () => onCambiarSuperior(0.02),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorMargen({
    required String titulo,
    required String subtitulo,
    required String valorLabel,
    required VoidCallback onRestar,
    required VoidCallback onSumar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF173024),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(
              size: 11.5,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(size: 10, color: Colors.white60),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btnStepper(icon: Icons.remove_rounded, onTap: onRestar),
              Text(
                valorLabel,
                style: AppTextStyles.number(
                  size: 15,
                  weight: FontWeight.w900,
                  color: AppColors.pistachio,
                ),
              ),
              _btnStepper(icon: Icons.add_rounded, onTap: onSumar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnStepper({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF10261D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
