// PANTALLA DE PERFIL Y ANÁLISIS HISTÓRICO
// Muestra la configuración de metas nutricionales, bandas de tolerancia asimétricas
// y tarjetas unificadas de estadísticas semanales (lunes a domingo con historial anterior).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../diario/presentation/viewmodels/diario_viewmodel.dart';
import '../viewmodels/perfil_viewmodel.dart';
import '../widgets/editar_metas_modal.dart';
import '../widgets/estadisticas_semanales_card.dart';
import '../widgets/metas_nutricionales_card.dart';
import '../widgets/tolerancia_objetivo_card.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final diarioVM = context.watch<DiarioViewModel>();
    final perfilVM = context.read<PerfilViewModel>();
    if (!_inicializado) {
      _inicializado = true;
      perfilVM.inicializar(diarioVM.todosLosDias);
    } else if (perfilVM.semanaOffset == 0) {
      perfilVM.recalcularMetricas(diarioVM.todosLosDias);
    }
  }

  Future<void> _abrirEditarMetas() async {
    final perfilVM = context.read<PerfilViewModel>();
    final diarioVM = context.read<DiarioViewModel>();

    final res = await EditarMetasModal.show(
      context,
      configActual: perfilVM.config,
    );

    if (res != null && mounted) {
      final kcal = (res['kcal'] as num).toInt();
      final p = (res['p'] as num).toDouble();
      final c = (res['c'] as num).toDouble();
      final g = (res['g'] as num).toDouble();

      await perfilVM.actualizarMetas(
        metaCalorias: kcal,
        metaProteinas: p,
        metaCarbos: c,
        metaGrasas: g,
        historial: diarioVM.todosLosDias,
      );

      // Sincronización en tiempo real con el día en curso en el Dashboard
      diarioVM.actualizarMetasDiaSeleccionado(
        metaCalorias: kcal,
        metaProteinas: p,
        metaCarbos: c,
        metaGrasas: g,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.forestDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                'Metas actualizadas: $kcal kcal · P ${p.round()}g · C ${c.round()}g · G ${g.round()}g',
                style: AppTextStyles.body(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilVM = context.watch<PerfilViewModel>();
    final diarioVM = context.watch<DiarioViewModel>();
    final config = perfilVM.config;
    final metricas = perfilVM.metricas;

    return Scaffold(
      backgroundColor: AppColors.forestDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MI PERFIL & METAS',
                        style: AppTextStyles.title(
                          size: 17,
                          weight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Objetivos y consistencia nutricional',
                        style: AppTextStyles.body(
                          size: 12,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10261D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.pistachio.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.pistachio,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Container Verde: Metas Diarias
              MetasNutricionalesCard(
                config: config,
                onEditar: _abrirEditarMetas,
              ),
              const SizedBox(height: 14),

              // 2. Container Verde: Rango de Tolerancia (- y + independientes)
              ToleranciaObjetivoCard(
                config: config,
                onCambiarInferior: (delta) {
                  perfilVM.ajustarToleranciaInferior(
                    delta,
                    diarioVM.todosLosDias,
                  );
                },
                onCambiarSuperior: (delta) {
                  perfilVM.ajustarToleranciaSuperior(
                    delta,
                    diarioVM.todosLosDias,
                  );
                },
              ),
              const SizedBox(height: 14),

              // 3. Container Verde UNIFICADO: Estadísticas Semanales (Lunes a Domingo + Top Alimentos)
              EstadisticasSemanalesCard(
                metricas: metricas,
                offset: perfilVM.semanaOffset,
                onCambiarSemana: (offset) {
                  perfilVM.cambiarSemana(offset, diarioVM.todosLosDias);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
