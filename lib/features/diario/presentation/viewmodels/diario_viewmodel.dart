// VIEWMODEL DEL DIARIO NUTRICIONAL SEMANAL (PATRÓN MVVM)
// Gestiona el estado reactivo del día seleccionado, registro y edición de comidas,
// cálculo de salud metabólica (Health Score) y delegación a la capa de persistencia.

import 'package:flutter/foundation.dart';
import '../../data/repositories/meal_health_repository_impl.dart';
import '../../domain/entities/comida_item.dart';
import '../../domain/entities/diario_dia.dart';
import '../../domain/entities/meal_health_evaluation.dart';
import '../../domain/repositories/diario_repository.dart';
import '../../domain/usecases/evaluate_meal_health_usecase.dart';
import '../../domain/usecases/health_score_failure_mapper.dart';
import 'health_score_eval_state.dart';

/// Estado del diario de toda la semana. La vista lee con watch/select y dispara con read.
class DiarioViewModel extends ChangeNotifier {
  final DiarioRepository repository;
  final EvaluateMealHealthUseCase _evaluateMealHealthUseCase;

  late final Map<int, DiarioDia> _dias;
  late int _diaSeleccionadoIndex;
  final Map<String, HealthScoreEvalState> _healthScoreStates = {};
  bool _disposed = false;

  DiarioViewModel({
    required this.repository,
    EvaluateMealHealthUseCase? evaluateMealHealthUseCase,
  }) : _evaluateMealHealthUseCase =
           evaluateMealHealthUseCase ??
           EvaluateMealHealthUseCase(repository: MealHealthRepositoryImpl()) {
    _dias = repository.getDiasIniciales();
    final hoyIdx = _dias.values.toList().indexWhere(
      (d) => d.diaNombre == 'Hoy',
    );
    _diaSeleccionadoIndex = hoyIdx != -1 ? hoyIdx : 30;
  }

  /// Días consecutivos de racha alcanzados calculados cronológicamente
  int get rachaDias {
    final lista = _dias.values.toList();
    final hoyIdx = lista.indexWhere((d) => d.diaNombre == 'Hoy');
    final actualIdx = hoyIdx != -1 ? hoyIdx : lista.length - 1;

    int racha = 0;
    if (lista[actualIdx].caloriasActuales > 0) {
      racha = 1;
    }

    for (int i = actualIdx - 1; i >= 0; i--) {
      final dia = lista[i];
      final min = (dia.metaCalorias * 0.9).round();
      final max = (dia.metaCalorias * 1.1).round();
      if (dia.caloriasActuales >= min && dia.caloriasActuales <= max) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  /// Indica si un día específico cumplió el objetivo calórico dentro del rango
  bool diaTieneRacha(int index) {
    final dia = _dias[index];
    if (dia == null || dia.caloriasActuales == 0) return false;
    final min = (dia.metaCalorias * 0.9).round();
    final max = (dia.metaCalorias * 1.1).round();
    return dia.caloriasActuales >= min && dia.caloriasActuales <= max;
  }

  /// Índice donde se encuentra el día "Hoy"
  int get indexHoy {
    final idx = _dias.values.toList().indexWhere((d) => d.diaNombre == 'Hoy');
    return idx != -1 ? idx : 30;
  }

  DiarioDia get diaActual => _dias[_diaSeleccionadoIndex]!;

  int get diaSeleccionadoIndex => _diaSeleccionadoIndex;

  List<String> get nombresDias => _dias.values.map((d) => d.labelPill).toList();

  List<String> get numerosDias => _dias.values.map((d) {
    final match = RegExp(r'\d+').firstMatch(d.labelPill);
    return match?.group(0) ?? '';
  }).toList();

  HealthScoreEvalState healthScoreStateFor(String comidaId) =>
      _healthScoreStates[comidaId] ?? const HealthScoreEvalIdle();

  bool isEvaluatingHealthScore(String comidaId) =>
      _healthScoreStates[comidaId] is HealthScoreEvaluating;

  ComidaItem? buscarComidaPorId(String comidaId) {
    for (final meal in diaActual.comidas) {
      if (meal.id == comidaId) return meal;
    }
    for (final dia in _dias.values) {
      for (final meal in dia.comidas) {
        if (meal.id == comidaId) return meal;
      }
    }
    return null;
  }

  HealthScoreSheetSnapshot healthScoreSnapshotFor(String comidaId) {
    final comida = buscarComidaPorId(comidaId);
    return HealthScoreSheetSnapshot(
      healthScore: comida?.healthScore,
      razonHealthScore: comida?.explicacionHealthScore,
      isStale: comida?.healthScoreDesactualizado ?? false,
      hasIngredients: comida != null && comida.ingredientes.isNotEmpty,
      evalState: healthScoreStateFor(comidaId),
    );
  }

  void seleccionarDia(int index) {
    if (index < 0 || index >= _dias.length) return;
    if (_diaSeleccionadoIndex == index) return;

    _diaSeleccionadoIndex = index;
    _notifySafe();
  }

  /// Suma una comida de muestra al día seleccionado y la devuelve para que la vista dé feedback.
  ComidaItem agregarComidaAleatoria() {
    final actual = diaActual;
    final nueva = repository.generarComidaAleatoria(actual.cantidadComidas + 1);

    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      comidas: [...actual.comidas, nueva],
    );
    _notifySafe();
    return nueva;
  }

  /// Agrega una comida armada al día seleccionado
  void registrarComida(ComidaItem nuevaComida) {
    final actual = diaActual;
    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      comidas: [...actual.comidas, nuevaComida],
    );
    repository.guardarDias(_dias);
    _notifySafe();
  }

  /// Actualiza los ingredientes o datos de una comida existente y recalcula los totales del día
  bool actualizarComida(ComidaItem comidaActualizada) {
    final actual = diaActual;
    final index = actual.comidas.indexWhere(
      (c) => c.id == comidaActualizada.id,
    );
    if (index == -1) return false;

    final nuevas = List<ComidaItem>.from(actual.comidas);
    nuevas[index] = comidaActualizada;

    _dias[_diaSeleccionadoIndex] = actual.copyWith(comidas: nuevas);
    _healthScoreStates[comidaActualizada.id] = const HealthScoreEvalIdle();
    repository.guardarDias(_dias);
    _notifySafe();
    return true;
  }

  /// Devuelve false si la comida no existe en el día seleccionado.
  bool eliminarComida(String comidaId) {
    final actual = diaActual;
    final restantes = actual.comidas.where((c) => c.id != comidaId).toList();
    if (restantes.length == actual.comidas.length) return false;

    _dias[_diaSeleccionadoIndex] = actual.copyWith(comidas: restantes);
    _healthScoreStates.remove(comidaId);
    repository.guardarDias(_dias);
    _notifySafe();
    return true;
  }

  /// Evaluates or refreshes the AI Health Score for [comidaId] and persists it.
  Future<bool> evaluarHealthScoreComida(
    String comidaId, {
    String languageCode = 'es',
  }) async {
    if (_disposed || isEvaluatingHealthScore(comidaId)) return false;

    final target = _locateMealWithDay(comidaId);
    if (target == null || target.comida.ingredientes.isEmpty) {
      return false;
    }

    final input = MealHealthEvaluationInput.fromComidaItem(target.comida);
    final fingerprint = input.computeFingerprint();

    _healthScoreStates[comidaId] = const HealthScoreEvaluating();
    _notifySafe();

    final result = await _evaluateMealHealthUseCase(
      input,
      languageCode: languageCode,
    );
    if (_disposed) return false;

    final day = _dias[target.dayIndex];
    if (day == null) {
      _healthScoreStates.remove(comidaId);
      _notifySafe();
      return false;
    }

    final mealIndex = day.comidas.indexWhere((c) => c.id == comidaId);
    if (mealIndex == -1) {
      _healthScoreStates.remove(comidaId);
      _notifySafe();
      return false;
    }

    final latestComida = day.comidas[mealIndex];
    final latestFingerprint = MealHealthEvaluationInput.fromComidaItem(
      latestComida,
    ).computeFingerprint();
    if (latestFingerprint != fingerprint) {
      _healthScoreStates[comidaId] = const HealthScoreEvalIdle();
      _notifySafe();
      return false;
    }

    switch (result) {
      case MealHealthSuccess(:final evaluation):
        final updated = latestComida.copyWith(
          healthScore: evaluation.healthScore,
          explicacionHealthScore: evaluation.razonHealthScore,
          healthScoreDesactualizado: false,
        );
        final updatedMeals = List<ComidaItem>.from(day.comidas);
        updatedMeals[mealIndex] = updated;
        _dias[target.dayIndex] = day.copyWith(comidas: updatedMeals);
        await repository.guardarDias(_dias);
        if (_disposed) return false;

        _healthScoreStates[comidaId] = HealthScoreEvalSuccess(
          healthScore: evaluation.healthScore,
          razonHealthScore: evaluation.razonHealthScore,
        );
        _notifySafe();
        return true;
      case MealHealthError(:final failure):
        final mapped = HealthScoreFailureMapper.map(failure);
        _healthScoreStates[comidaId] = HealthScoreEvalError(
          message: mapped.message,
          type: mapped.type,
        );
        _notifySafe();
        return false;
    }
  }

  ({int dayIndex, ComidaItem comida})? _locateMealWithDay(String comidaId) {
    for (final meal in diaActual.comidas) {
      if (meal.id == comidaId) {
        return (dayIndex: _diaSeleccionadoIndex, comida: meal);
      }
    }
    for (final entry in _dias.entries) {
      for (final meal in entry.value.comidas) {
        if (meal.id == comidaId) {
          return (dayIndex: entry.key, comida: meal);
        }
      }
    }
    return null;
  }

  /// Lista ordenada de todos los días de la semana para análisis histórico.
  List<DiarioDia> get todosLosDias => _dias.values.toList();

  /// Actualiza las metas nutricionales del día actual o seleccionado, preservando los días pasados.
  void actualizarMetasDiaSeleccionado({
    int? metaCalorias,
    double? metaProteinas,
    double? metaCarbos,
    double? metaGrasas,
  }) {
    final actual = diaActual;
    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      metaCalorias: metaCalorias ?? actual.metaCalorias,
      metaProteinas: metaProteinas ?? actual.metaProteinas,
      metaCarbos: metaCarbos ?? actual.metaCarbos,
      metaGrasas: metaGrasas ?? actual.metaGrasas,
    );
    repository.guardarDias(_dias);
    _notifySafe();
  }

  void _notifySafe() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
