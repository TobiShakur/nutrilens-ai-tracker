// PANTALLA DE PERFIL Y ANÁLISIS HISTÓRICO
// Muestra la configuración de metas nutricionales, bandas de tolerancia asimétricas
// y tarjetas unificadas de estadísticas semanales (lunes a domingo con historial anterior).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/localization/locale_provider.dart';
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
  DiarioViewModel? _diarioVM;
  PerfilViewModel? _perfilVM;

  void _onDiarioChanged() {
    if (!mounted) return;
    final diarioVM = _diarioVM;
    final perfilVM = _perfilVM;
    if (diarioVM != null && perfilVM != null && perfilVM.semanaOffset == 0) {
      perfilVM.recalcularMetricas(diarioVM.todosLosDias);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final diarioVM = context.read<DiarioViewModel>();
    final perfilVM = context.read<PerfilViewModel>();
    if (_diarioVM != diarioVM) {
      _diarioVM?.removeListener(_onDiarioChanged);
      _diarioVM = diarioVM;
      _diarioVM?.addListener(_onDiarioChanged);
    }
    _perfilVM = perfilVM;

    if (!_inicializado) {
      _inicializado = true;
      final historial = diarioVM.todosLosDias;
      Future.microtask(() {
        if (!mounted) return;
        perfilVM.inicializar(historial);
      });
    }
  }

  @override
  void dispose() {
    _diarioVM?.removeListener(_onDiarioChanged);
    super.dispose();
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
        final l10n = context.l10n;
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
                l10n.profileGoalsUpdated(kcal, p.round(), c.round(), g.round()),
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

  Future<void> _abrirSelectorIdioma() async {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = context.l10n;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final activeCode = localeProvider.languageCode;
        return Dialog(
          backgroundColor: const Color(0xFF10261D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF1E3A2F)),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.pistachio.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: AppColors.pistachio,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.selectLanguageTitle,
                          style: AppTextStyles.title(
                            size: 15,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectLanguageSubtitle,
                    style: AppTextStyles.body(
                      size: 12,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LanguageOptionTile(
                    label: l10n.languageSpanish,
                    codeLabel: 'ES',
                    isSelected: activeCode == 'es',
                    onTap: () async {
                      await localeProvider.setLocale(const Locale('es'));
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _LanguageOptionTile(
                    label: l10n.languageEnglish,
                    codeLabel: 'EN',
                    isSelected: activeCode == 'en',
                    onTap: () async {
                      await localeProvider.setLocale(const Locale('en'));
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeProvider = context.watch<LocaleProvider>();
    final perfilVM = context.watch<PerfilViewModel>();
    final diarioVM = context.watch<DiarioViewModel>();
    final config = perfilVM.config;
    final metricas = perfilVM.metricas;
    final currentLangLabel = localeProvider.isEnglish
        ? l10n.languageEnglish
        : l10n.languageSpanish;

    return Scaffold(
      backgroundColor: AppColors.forestDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 125),
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
                        l10n.profileTitle,
                        style: AppTextStyles.title(
                          size: 17,
                          weight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.profileSubtitle,
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
              const SizedBox(height: 14),

              // 4. Selector de Idioma (al final del scroll)
              _LanguageSelectorCard(
                label: l10n.language,
                currentLanguage: currentLangLabel,
                onTap: _abrirSelectorIdioma,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelectorCard extends StatelessWidget {
  final String label;
  final String currentLanguage;
  final VoidCallback onTap;

  const _LanguageSelectorCard({
    required this.label,
    required this.currentLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $currentLanguage',
      child: Material(
        color: const Color(0xFF10261D),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: const Key('perfil-language-selector'),
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1E3A2F)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.pistachio.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: AppColors.pistachio,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.title(
                      size: 13.5,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  currentLanguage,
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.pistachio,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String label;
  final String codeLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.label,
    required this.codeLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF1A382B) : const Color(0xFF173024),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.pistachio.withValues(alpha: 0.7)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pistachio.withValues(
                    alpha: isSelected ? 0.22 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  codeLabel,
                  style: AppTextStyles.body(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.pistachio,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.pistachio,
                  size: 20,
                )
              else
                const Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: Colors.white30,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
