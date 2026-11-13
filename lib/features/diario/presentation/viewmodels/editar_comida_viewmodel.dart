import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../data/repositories/meal_health_repository_impl.dart';
import '../../domain/entities/comida_ingrediente.dart';
import '../../domain/entities/comida_item.dart';
import '../../domain/entities/meal_health_evaluation.dart';
import '../../domain/usecases/evaluate_meal_health_usecase.dart';
import '../../domain/usecases/health_score_failure_mapper.dart';
import 'health_score_eval_state.dart';

/// Scoped draft ViewModel for [EditarComidaSheet] managing ingredient edits,
/// stale Health Score dirty-tracking, and on-demand Gemini recalculation.
class EditarComidaViewModel extends ChangeNotifier {
  static const List<String> availableMealTypes = [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Snack',
  ];

  final ComidaItem _comidaOriginal;
  final EvaluateMealHealthUseCase _evaluateMealHealthUseCase;

  String _titulo;
  String _tipoComida;
  final List<ComidaIngrediente> _ingredientes;
  int? _healthScore;
  String? _explicacionHealthScore;
  bool _healthScoreDesactualizado;
  HealthScoreEvalState _healthScoreEvalState = const HealthScoreEvalIdle();
  bool _disposed = false;

  EditarComidaViewModel({
    required ComidaItem comida,
    EvaluateMealHealthUseCase? evaluateMealHealthUseCase,
  }) : _comidaOriginal = comida,
       _evaluateMealHealthUseCase =
           evaluateMealHealthUseCase ??
           EvaluateMealHealthUseCase(repository: MealHealthRepositoryImpl()),
       _titulo = comida.titulo,
       _tipoComida = _resolveInitialType(comida.encabezadoTipo),
       _ingredientes = List<ComidaIngrediente>.from(comida.ingredientes),
       _healthScore = comida.healthScore,
       _explicacionHealthScore = comida.explicacionHealthScore,
       _healthScoreDesactualizado = comida.healthScoreDesactualizado;

  static String _resolveInitialType(String rawType) {
    return availableMealTypes.contains(rawType)
        ? rawType
        : availableMealTypes.first;
  }

  String get titulo => _titulo;
  String get tipoComida => _tipoComida;
  UnmodifiableListView<ComidaIngrediente> get ingredientes =>
      UnmodifiableListView(_ingredientes);
  int? get healthScore => _healthScore;
  String? get explicacionHealthScore => _explicacionHealthScore;
  bool get healthScoreDesactualizado => _healthScoreDesactualizado;
  HealthScoreEvalState get healthScoreEvalState => _healthScoreEvalState;

  int get totalCalorias => _ingredientes.fold(0, (acc, i) => acc + i.calorias);

  double get totalProteinas => double.parse(
    _ingredientes.fold(0.0, (acc, i) => acc + i.proteinas).toStringAsFixed(1),
  );

  double get totalCarbos => double.parse(
    _ingredientes
        .fold(0.0, (acc, i) => acc + i.carbohidratos)
        .toStringAsFixed(1),
  );

  double get totalGrasas => double.parse(
    _ingredientes.fold(0.0, (acc, i) => acc + i.grasas).toStringAsFixed(1),
  );

  HealthScoreSheetSnapshot get healthScoreSnapshot => HealthScoreSheetSnapshot(
    healthScore: _healthScore,
    razonHealthScore: _explicacionHealthScore,
    isStale: _healthScoreDesactualizado,
    hasIngredients: _ingredientes.isNotEmpty,
    evalState: _healthScoreEvalState,
  );

  void setTitulo(String value) {
    if (_disposed || _titulo == value) return;
    _titulo = value;
    _notifySafe();
  }

  void setTipoComida(String value) {
    if (_disposed || _tipoComida == value) return;
    _tipoComida = value;
    _notifySafe();
  }

  void ajustarGramos(int index, double delta) {
    if (_disposed || index < 0 || index >= _ingredientes.length) return;
    final actual = _ingredientes[index];
    final nextGrams = (actual.gramos + delta).clamp(5.0, 1000.0);
    if (nextGrams == actual.gramos) return;

    _ingredientes[index] = actual.conGramos(nextGrams);
    _markIngredientsMutated();
  }

  void fijarGramos(int index, double gramos) {
    if (_disposed || index < 0 || index >= _ingredientes.length) return;
    final actual = _ingredientes[index];
    final clampedGrams = gramos.clamp(5.0, 1000.0);
    if (clampedGrams == actual.gramos) return;

    _ingredientes[index] = actual.conGramos(clampedGrams);
    _markIngredientsMutated();
  }

  void agregarIngrediente(IngredienteAlacena alacena, double gramos) {
    if (_disposed) return;
    final added = ComidaIngrediente.desdeAlacena(
      alacena: alacena,
      gramos: gramos,
    );
    _ingredientes.add(added);
    _markIngredientsMutated();
  }

  void eliminarIngrediente(int index) {
    if (_disposed || index < 0 || index >= _ingredientes.length) return;
    _ingredientes.removeAt(index);
    _markIngredientsMutated();
  }

  void _markIngredientsMutated() {
    if (_healthScore != null) {
      _healthScoreDesactualizado = true;
    }
    _healthScoreEvalState = const HealthScoreEvalIdle();
    _notifySafe();
  }

  MealHealthEvaluationInput _buildEvaluationInput() {
    final cleanTitle = _titulo.trim();
    return MealHealthEvaluationInput(
      titulo: cleanTitle.isEmpty ? _comidaOriginal.titulo : cleanTitle,
      ingredientes: _ingredientes
          .map(
            (i) => MealHealthIngredientInput(
              nombre: i.nombreConMarca,
              gramos: i.gramos,
              calorias: i.calorias,
              proteinas: i.proteinas,
              carbohidratos: i.carbohidratos,
              grasas: i.grasas,
            ),
          )
          .toList(growable: false),
      totalCalorias: totalCalorias,
      totalProteinas: totalProteinas,
      totalCarbohidratos: totalCarbos,
      totalGrasas: totalGrasas,
    );
  }

  /// Evaluates or refreshes the draft meal's Health Score without committing to
  /// [DiarioViewModel] until the user confirms saving.
  Future<bool> evaluarHealthScore({String languageCode = 'es'}) async {
    if (_disposed ||
        _healthScoreEvalState is HealthScoreEvaluating ||
        _ingredientes.isEmpty) {
      return false;
    }

    final input = _buildEvaluationInput();
    final fingerprint = input.computeFingerprint();

    _healthScoreEvalState = const HealthScoreEvaluating();
    _notifySafe();

    final result = await _evaluateMealHealthUseCase(
      input,
      languageCode: languageCode,
    );
    if (_disposed) return false;

    final latestFingerprint = _buildEvaluationInput().computeFingerprint();
    if (latestFingerprint != fingerprint) {
      _healthScoreEvalState = const HealthScoreEvalIdle();
      _notifySafe();
      return false;
    }

    switch (result) {
      case MealHealthSuccess(:final evaluation):
        _healthScore = evaluation.healthScore;
        _explicacionHealthScore = evaluation.razonHealthScore;
        _healthScoreDesactualizado = false;
        _healthScoreEvalState = HealthScoreEvalSuccess(
          healthScore: evaluation.healthScore,
          razonHealthScore: evaluation.razonHealthScore,
        );
        _notifySafe();
        return true;
      case MealHealthError(:final failure):
        final mapped = HealthScoreFailureMapper.map(failure);
        _healthScoreEvalState = HealthScoreEvalError(
          message: mapped.message,
          type: mapped.type,
        );
        _notifySafe();
        return false;
    }
  }

  ComidaItem buildUpdatedComida() {
    final cleanTitle = _titulo.trim();
    return _comidaOriginal.copyWith(
      titulo: cleanTitle.isEmpty ? _comidaOriginal.titulo : cleanTitle,
      tipoComida: _tipoComida.toUpperCase(),
      ingredientes: List.unmodifiable(_ingredientes),
      healthScore: _healthScore,
      clearHealthScore: _healthScore == null,
      explicacionHealthScore: _explicacionHealthScore,
      clearExplicacionHealthScore: _explicacionHealthScore == null,
      healthScoreDesactualizado: _healthScoreDesactualizado,
    );
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
