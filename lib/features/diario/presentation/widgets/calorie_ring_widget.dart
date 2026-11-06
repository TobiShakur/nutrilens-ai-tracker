// WIDGET DEL ANILLO MULTICAPA CALÓRICO CON CUSTOM PAINTER
// Renderiza el arco de progreso verde con brillo, el exceso naranja (>100%) y el exceso rojo (>200%).
// Respeta cero estricto (sin perilla encendida) cuando las calorías registradas son 0.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Anillo circular multi-capa de progreso calórico
/// - Capa 1: Verde Pistacho (0 a 100% de la meta)
/// - Capa 2: Naranja brillante (100% a 200% - Primer exceso)
/// - Capa 3: Rojo intenso (> 200% - Segundo exceso crítico)
class CalorieRingWidget extends StatelessWidget {
  final int metaCalorias;
  final int caloriasActuales;
  final int caloriasRestantes;
  final int caloriasExtras;
  final double ratioVerde;
  final double ratioNaranja;
  final double ratioRojo;

  const CalorieRingWidget({
    super.key,
    required this.metaCalorias,
    required this.caloriasActuales,
    required this.caloriasRestantes,
    required this.caloriasExtras,
    required this.ratioVerde,
    required this.ratioNaranja,
    required this.ratioRojo,
  });

  @override
  Widget build(BuildContext context) {
    final bool estaExcedido = caloriasExtras > 0;
    final bool estaCritico = ratioRojo > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final ringSize = (availableWidth * 0.48).clamp(145.0, 192.0);
        final numberFontSize = (ringSize * 0.27).clamp(36.0, 48.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Izquierda: Meta Total
            Expanded(
              child: _buildSideStat(
                icon: Icons.track_changes_outlined,
                iconColor: AppColors.pistachio,
                label: 'Meta Total',
                value: '$metaCalorias',
                unit: 'kcal',
              ),
            ),

            // 2. Centro: Anillo Circular Multi-Capa con las Calorías Actuales
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _MultiLayerRingPainter(
                      ratioVerde: caloriasActuales <= 0
                          ? 0.0
                          : ratioVerde.clamp(0.0, 1.0),
                      ratioNaranja: caloriasActuales <= metaCalorias
                          ? 0.0
                          : ratioNaranja,
                      ratioRojo: ratioRojo,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        estaCritico
                            ? '¡Exceso Crítico!'
                            : (estaExcedido ? '¡Exceso!' : 'Actuales'),
                        style: TextStyle(
                          color: estaCritico
                              ? AppColors.exceedRed
                              : (estaExcedido
                                    ? AppColors.exceedOrange
                                    : AppColors.textMutedLight),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$caloriasActuales',
                          style: AppTextStyles.number(
                            size: numberFontSize,
                            weight: FontWeight.w900,
                            color: estaCritico
                                ? AppColors.exceedRed
                                : (estaExcedido
                                      ? AppColors.exceedOrange
                                      : Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        estaExcedido ? '+$caloriasExtras extras' : 'kcal',
                        style: TextStyle(
                          color: estaExcedido
                              ? (estaCritico
                                    ? AppColors.exceedRedSoft
                                    : AppColors.exceedOrangeSoft)
                              : AppColors.textMutedLight,
                          fontSize: 12,
                          fontWeight: estaExcedido
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Derecha: Restantes o Extras (según si se pasó)
            Expanded(
              child: estaExcedido
                  ? _buildSideStat(
                      icon: Icons.warning_amber_rounded,
                      iconColor: estaCritico
                          ? AppColors.exceedRed
                          : AppColors.exceedOrange,
                      label: 'Extras',
                      value: '+$caloriasExtras',
                      unit: 'kcal',
                      valueColor: estaCritico
                          ? AppColors.exceedRed
                          : AppColors.exceedOrange,
                    )
                  : _buildSideStat(
                      icon: Icons.timelapse_outlined,
                      iconColor: AppColors.pistachio,
                      label: 'Restantes',
                      value: '$caloriasRestantes',
                      unit: 'kcal',
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSideStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    Color valueColor = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.number(
              size: 21,
              weight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ),
        Text(
          unit,
          style: const TextStyle(color: AppColors.textMutedLight, fontSize: 11),
        ),
      ],
    );
  }
}

class _MultiLayerRingPainter extends CustomPainter {
  final double ratioVerde; // 0.0 a 1.0 (Verde Pistacho)
  final double ratioNaranja; // 0.0 a 1.0 (Naranja - Primer exceso)
  final double ratioRojo; // 0.0 a 1.0 (Rojo - Segundo exceso)

  _MultiLayerRingPainter({
    required this.ratioVerde,
    required this.ratioNaranja,
    required this.ratioRojo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.088;
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2;

    // 1. Pista de Fondo oscura
    final bgPaint = Paint()
      ..color = AppColors.forestSlot
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Capa 1: Verde Pistacho
    if (ratioVerde > 0.005) {
      final greenPaint = Paint()
        ..color = AppColors.pistachio
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final greenSweep = 2 * pi * ratioVerde;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        greenSweep,
        false,
        greenPaint,
      );
    }

    // 3. Capa 2: Naranja (se dibuja encima al pasar el 100%)
    if (ratioNaranja > 0) {
      final orangePaint = Paint()
        ..color = AppColors
            .exceedOrangeStroke // Naranja brillante
        ..strokeWidth = strokeWidth + 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final orangeSweep = 2 * pi * ratioNaranja;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        orangeSweep,
        false,
        orangePaint,
      );
    }

    // 4. Capa 3: Rojo (se dibuja encima al pasar el 200%)
    if (ratioRojo > 0) {
      final redPaint = Paint()
        ..color = AppColors
            .exceedRedStroke // Rojo intenso
        ..strokeWidth = strokeWidth + 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final redSweep = 2 * pi * ratioRojo;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        redSweep,
        false,
        redPaint,
      );
    }

    // 5. Indicador Circular (Dot) en la punta del arco más alto (solo si hay calorías consumidas)
    if (ratioVerde > 0.005) {
      double activeSweep;
      Color dotGlowColor;

      if (ratioRojo > 0) {
        activeSweep = 2 * pi * ratioRojo;
        dotGlowColor = AppColors.exceedRedStroke;
      } else if (ratioNaranja > 0) {
        activeSweep = 2 * pi * ratioNaranja;
        dotGlowColor = AppColors.exceedOrangeStroke;
      } else {
        activeSweep = 2 * pi * ratioVerde;
        dotGlowColor = AppColors.pistachio;
      }

      final endAngle = startAngle + activeSweep;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);

      final dotShadowPaint = Paint()
        ..color = dotGlowColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.75, dotShadowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.55, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLayerRingPainter oldDelegate) {
    return oldDelegate.ratioVerde != ratioVerde ||
        oldDelegate.ratioNaranja != ratioNaranja ||
        oldDelegate.ratioRojo != ratioRojo;
  }
}
