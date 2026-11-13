import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../domain/entities/comida_item.dart';
import '../viewmodels/diario_viewmodel.dart';
import '../viewmodels/health_score_eval_state.dart';
import 'editar_comida_sheet.dart';
import 'health_score_badge.dart';
import 'health_score_detail_sheet.dart';

class DetalleComidaSheet extends StatelessWidget {
  final ComidaItem comida;
  final VoidCallback onDelete;

  const DetalleComidaSheet({
    super.key,
    required this.comida,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required ComidaItem comida,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleComidaSheet(comida: comida, onDelete: onDelete),
    );
  }

  DiarioViewModel? _tryWatchDiario(BuildContext context) {
    try {
      return Provider.of<DiarioViewModel>(context, listen: true);
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    ComidaItem liveComida,
  ) async {
    final confirmado = await ConfirmDeleteDialog.show(
      context,
      titulo: '¿Eliminar comida?',
      mensaje: 'Se eliminará "${liveComida.encabezadoTipo}" de tus comidas.',
    );
    if (confirmado && context.mounted) {
      onDelete();
      Navigator.pop(context); // Cierra el bottom sheet
    }
  }

  void _openHealthScoreDetail(
    BuildContext context,
    DiarioViewModel diarioVM,
    String comidaId,
  ) {
    HealthScoreDetailSheet.show(
      context,
      listenable: diarioVM,
      readSnapshot: () => diarioVM.healthScoreSnapshotFor(comidaId),
      onEvaluate: () => diarioVM.evaluarHealthScoreComida(comidaId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diarioVM = _tryWatchDiario(context);
    final liveComida = diarioVM?.buscarComidaPorId(comida.id) ?? comida;
    final evalState =
        diarioVM?.healthScoreStateFor(liveComida.id) ??
        const HealthScoreEvalIdle();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Header minimalista con badge interactivo de Health Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  liveComida.icono,
                  color: AppColors.forestDark,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveComida.encabezadoTipo,
                      style: AppTextStyles.title(
                        size: 17,
                        weight: FontWeight.w900,
                        color: AppColors.forestDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hora: ${liveComida.hora} hs',
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: AppColors.textMutedAccessible,
                            ),
                          ),
                        ),
                        HealthScoreBadge(
                          healthScore: liveComida.healthScore,
                          isStale: liveComida.healthScoreDesactualizado,
                          isLoading: evalState is HealthScoreEvaluating,
                          hasError: evalState is HealthScoreEvalError,
                          onTap: diarioVM != null
                              ? () => _openHealthScoreDetail(
                                  context,
                                  diarioVM,
                                  liveComida.id,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bloque de Calorías destacado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aporte energético',
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${liveComida.calorias}',
                          style: AppTextStyles.number(
                            size: 28,
                            weight: FontWeight.w900,
                            color: AppColors.forestDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal',
                          style: AppTextStyles.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (liveComida.metaCalorias != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pistachio.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Meta: ${liveComida.metaCalorias} kcal',
                      style: AppTextStyles.number(
                        size: 12,
                        weight: FontWeight.w800,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 3 Pastillas de Macros
          Row(
            children: [
              Expanded(
                child: _MacroPill(
                  label: 'Proteínas',
                  value: '${liveComida.proteinas.round()}g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: 'Carbos',
                  value: '${liveComida.carbohidratos.round()}g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: 'Grasas',
                  value: '${liveComida.grasas.round()}g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Desglose de Ingredientes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredientes (${liveComida.ingredientes.length})',
                style: AppTextStyles.title(size: 14.5, weight: FontWeight.w800),
              ),
              Text(
                '${liveComida.ingredientes.fold(0.0, (acc, i) => acc + i.gramos).round()}g total',
                style: AppTextStyles.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (liveComida.ingredientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                liveComida.detalleComida,
                style: AppTextStyles.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.forestDark,
                ),
              ),
            )
          else
            ...liveComida.ingredientes.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombreConMarca,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              size: 13,
                              weight: FontWeight.w800,
                              color: AppColors.forestDark,
                            ),
                          ),
                          Text(
                            'P ${item.proteinas}g · C ${item.carbohidratos}g · G ${item.grasas}g',
                            style: AppTextStyles.body(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.porcionLabel,
                            style: AppTextStyles.number(
                              size: 11.5,
                              weight: FontWeight.w800,
                              color: AppColors.forestDark,
                            ),
                          ),
                          Text(
                            '${item.calorias} kcal',
                            style: AppTextStyles.body(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          // Botones de Acción: Modificar y Eliminar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forestDark,
                    side: const BorderSide(
                      color: AppColors.forestDark,
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Modificar',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    EditarComidaSheet.show(context, comida: liveComida);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alertRed,
                    side: BorderSide(
                      color: AppColors.alertRed.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Eliminar',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.alertRed,
                    ),
                  ),
                  onPressed: () => _confirmarEliminar(context, liveComida),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;

  const _MacroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.number(
              size: 14,
              weight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
