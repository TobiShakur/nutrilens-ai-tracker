// PANTALLA PRINCIPAL: DIARIO Y DASHBOARD DE NUTRICIÓN
// Presenta el Hero Card con selector semanal, anillo multicapa de calorías,
// desglose de macronutrientes, banner interactivo de Health Score y lista de comidas del día.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/diario_dia.dart';
import '../viewmodels/diario_viewmodel.dart';
import '../widgets/calorie_ring_widget.dart';
import '../widgets/detalle_comida_sheet.dart';
import '../widgets/health_score_banner.dart';
import '../widgets/macro_row_widget.dart';
import '../widgets/meal_card_widget.dart';
import '../widgets/week_selector.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiarioViewModel>();
    final dia = vm.diaActual;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroCard(dia: dia, vm: vm),
        ),
        SliverToBoxAdapter(
          child: HealthScoreBanner(
            healthScore: dia.promedioHealthScore,
            nivel: dia.nivelScore,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'COMIDAS · ${dia.cantidadComidas}',
              style: AppTextStyles.title(size: 14.5, weight: FontWeight.w700),
            ),
          ),
        ),
        if (dia.comidas.isEmpty)
          const SliverToBoxAdapter(child: _EmptyDayCard())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 125),
            sliver: SliverList.builder(
              itemCount: dia.comidas.length,
              itemBuilder: (context, index) {
                final comida = dia.comidas[index];
                return MealCardWidget(
                  comida: comida,
                  onTap: () => DetalleComidaSheet.show(
                    context,
                    comida: comida,
                    onDelete: () => context
                        .read<DiarioViewModel>()
                        .eliminarComida(comida.id),
                  ),
                  onDelete: () =>
                      context.read<DiarioViewModel>().eliminarComida(comida.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final DiarioDia dia;
  final DiarioViewModel vm;

  const _HeroCard({required this.dia, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: const BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: 16),
            WeekSelector(
              nombres: vm.nombresDias,
              seleccionado: vm.diaSeleccionadoIndex,
              onSelected: context.read<DiarioViewModel>().seleccionarDia,
            ),
            const SizedBox(height: 18),
            CalorieRingWidget(
              metaCalorias: dia.metaCalorias,
              caloriasActuales: dia.caloriasActuales,
              caloriasRestantes: dia.caloriasRestantes,
              caloriasExtras: dia.caloriasExtras,
              ratioVerde: dia.ratioVerde,
              ratioNaranja: dia.ratioNaranja,
              ratioRojo: dia.ratioRojo,
            ),
            const SizedBox(height: 16),
            MacroRowWidget(
              proteinasConsumidas: dia.proteinasConsumidas,
              metaProteinas: dia.metaProteinas,
              grasasConsumidas: dia.grasasConsumidas,
              metaGrasas: dia.metaGrasas,
              carbosConsumidos: dia.carbosConsumidos,
              metaCarbos: dia.metaCarbos,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final racha = context.select<DiarioViewModel, int>((vm) => vm.rachaDias);

    final String textoRacha;
    if (racha == 0) {
      textoRacha = 'Sin racha';
    } else if (racha == 1) {
      textoRacha = '1 día de racha';
    } else {
      textoRacha = '$racha días de racha';
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.pistachio,
          child: Text(
            'TG',
            style: AppTextStyles.display(size: 13, weight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buen día,',
                style: AppTextStyles.body(
                  size: 13,
                  color: AppColors.textMutedLight,
                ),
              ),
              Text(
                'Tobías',
                style: AppTextStyles.display(
                  size: 16,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF133C2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.pistachio.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                textoRacha,
                style: AppTextStyles.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.pistachio,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 36,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Todavía no hay comidas este día',
            style: AppTextStyles.body(size: 14.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Tocá "Sumar comida" para ver cómo se actualizan tus números.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
