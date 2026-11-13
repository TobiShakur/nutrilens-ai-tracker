import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../viewmodels/health_score_eval_state.dart';

/// Shared interactive modal sheet displaying AI Health Score calculation,
/// qualitative tier, rationale, stale-edit banner, and error recovery.
class HealthScoreDetailSheet extends StatefulWidget {
  final Listenable listenable;
  final HealthScoreSheetSnapshot Function() readSnapshot;
  final Future<bool> Function() onEvaluate;

  const HealthScoreDetailSheet({
    super.key,
    required this.listenable,
    required this.readSnapshot,
    required this.onEvaluate,
  });

  static Future<void> show(
    BuildContext context, {
    required Listenable listenable,
    required HealthScoreSheetSnapshot Function() readSnapshot,
    required Future<bool> Function() onEvaluate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthScoreDetailSheet(
        listenable: listenable,
        readSnapshot: readSnapshot,
        onEvaluate: onEvaluate,
      ),
    );
  }

  @override
  State<HealthScoreDetailSheet> createState() => _HealthScoreDetailSheetState();
}

class _HealthScoreDetailSheetState extends State<HealthScoreDetailSheet> {
  @override
  void initState() {
    super.initState();
    final initial = widget.readSnapshot();
    if (initial.healthScore == null &&
        initial.hasIngredients &&
        initial.evalState is! HealthScoreEvaluating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onEvaluate();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Score',
                            style: AppTextStyles.title(
                              size: 17,
                              weight: FontWeight.w900,
                              color: AppColors.forestDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Evaluación según ingredientes y porciones',
                            style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.textMutedAccessible,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: 'Cerrar',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.forestDark,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: widget.listenable,
                  builder: (context, _) {
                    final snapshot = widget.readSnapshot();
                    return Semantics(
                      liveRegion: true,
                      child: AnimatedSize(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _buildBody(context, snapshot),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HealthScoreSheetSnapshot snapshot) {
    final evalState = snapshot.evalState;

    if (evalState is HealthScoreEvaluating) {
      return const _LoadingBody(key: ValueKey('hs_loading'));
    }

    if (evalState is HealthScoreEvalError) {
      return _ErrorBody(
        key: ValueKey('hs_error_${evalState.type.name}'),
        previousScore: snapshot.healthScore,
        message: evalState.message,
        hasIngredients: snapshot.hasIngredients,
        onRetry: widget.onEvaluate,
        onClose: () => Navigator.pop(context),
      );
    }

    if (!snapshot.hasIngredients && snapshot.healthScore == null) {
      return _EmptyIngredientsBody(
        key: const ValueKey('hs_empty'),
        onClose: () => Navigator.pop(context),
      );
    }

    if (snapshot.healthScore != null) {
      return _ScoredBody(
        key: ValueKey('hs_scored_${snapshot.healthScore}_${snapshot.isStale}'),
        score: snapshot.healthScore!,
        razon: snapshot.razonHealthScore,
        isStale: snapshot.isStale,
        hasIngredients: snapshot.hasIngredients,
        onEvaluate: widget.onEvaluate,
        onClose: () => Navigator.pop(context),
      );
    }

    return const _LoadingBody(key: ValueKey('hs_loading_auto'));
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 164),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: AppColors.forestDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Calculando puntaje...',
              textAlign: TextAlign.center,
              style: AppTextStyles.title(
                size: 15,
                weight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analizando ingredientes, cantidades y perfil nutricional',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.textMutedAccessible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIngredientsBody extends StatelessWidget {
  final VoidCallback onClose;

  const _EmptyIngredientsBody({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 164),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              'Agregá al menos un ingrediente para calcular el Health Score.',
              style: AppTextStyles.body(
                size: 13.5,
                weight: FontWeight.w500,
                color: AppColors.textDark,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestDark,
                      side: const BorderSide(color: AppColors.forestDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onClose,
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pistachio,
                      foregroundColor: AppColors.forestDark,
                      disabledBackgroundColor: AppColors.borderLight,
                      disabledForegroundColor: AppColors.textMutedAccessible,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: null,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Calcular puntaje'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoredBody extends StatelessWidget {
  final int score;
  final String? razon;
  final bool isStale;
  final bool hasIngredients;
  final Future<bool> Function() onEvaluate;
  final VoidCallback onClose;

  const _ScoredBody({
    super.key,
    required this.score,
    required this.razon,
    required this.isStale,
    required this.hasIngredients,
    required this.onEvaluate,
    required this.onClose,
  });

  String _tierLabel(int value) {
    if (value >= 85) return 'Perfil nutricional excelente';
    if (value >= 70) return 'Buen balance nutricional';
    if (value >= 50) return 'Balance moderado';
    return 'Perfil nutricional bajo';
  }

  Color _ringColor(int value) {
    if (value >= 70) return AppColors.scoreGood;
    if (value >= 50) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    final trimmedReason = razon?.trim();
    final hasExplanation = trimmedReason != null && trimmedReason.isNotEmpty;
    final highlightRefresh = isStale || !hasExplanation;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 164),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _ScoreRingPainter(
                    progress: (score / 100).clamp(0.0, 1.0),
                    color: _ringColor(score),
                    trackColor: AppColors.borderLight,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style:
                              AppTextStyles.number(
                                size: 20,
                                weight: FontWeight.w900,
                                color: AppColors.textDark,
                              ).copyWith(
                                height: 1.0,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                        Text(
                          '/100',
                          style:
                              AppTextStyles.number(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: AppColors.textMutedAccessible,
                              ).copyWith(
                                height: 1.1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tierLabel(score),
                      style: AppTextStyles.title(
                        size: 15.5,
                        weight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isStale
                          ? 'Modificado desde el último cálculo'
                          : (hasExplanation
                                ? 'Evaluado sobre los ingredientes actuales'
                                : 'Sin detalle guardado para esta comida'),
                      style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: isStale
                            ? AppColors.scoreMidText
                            : AppColors.textMutedAccessible,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isStale) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.pistachioLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pistachioDark),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.forestDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editaste ingredientes o gramos. Recalculá para actualizar el puntaje.',
                      style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              hasExplanation
                  ? trimmedReason
                  : 'Todavía no hay una explicación generada. Tocá "Recalcular puntaje" para obtener el análisis de tus ingredientes.',
              style: AppTextStyles.body(
                size: 13.5,
                weight: FontWeight.w500,
                color: hasExplanation
                    ? AppColors.textDark
                    : AppColors.textMutedAccessible,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (highlightRefresh)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forestDark,
                        side: const BorderSide(color: AppColors.forestDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onClose,
                      child: const Text('Cerrar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pistachio,
                        foregroundColor: AppColors.forestDark,
                        disabledBackgroundColor: AppColors.borderLight,
                        disabledForegroundColor: AppColors.textMutedAccessible,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: hasIngredients ? () => onEvaluate() : null,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Recalcular puntaje'),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forestDark,
                        side: const BorderSide(
                          color: AppColors.forestDark,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: hasIngredients ? () => onEvaluate() : null,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Recalcular'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onClose,
                      child: const Text('Entendido'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final int? previousScore;
  final String message;
  final bool hasIngredients;
  final Future<bool> Function() onRetry;
  final VoidCallback onClose;

  const _ErrorBody({
    super.key,
    required this.previousScore,
    required this.message,
    required this.hasIngredients,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final contextLabel = previousScore != null
        ? 'Puntaje actual conservado: $previousScore/100'
        : 'Puntaje actual: ?/100';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 164),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            contextLabel,
            style: AppTextStyles.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.textMutedAccessible,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorTintLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.alertRed.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: AppColors.alertRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No se pudo calcular el Health Score',
                        style: AppTextStyles.body(
                          size: 13.5,
                          weight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: AppTextStyles.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMutedAccessible,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onClose,
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.borderLight,
                      disabledForegroundColor: AppColors.textMutedAccessible,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: hasIngredients ? () => onRetry() : null,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
