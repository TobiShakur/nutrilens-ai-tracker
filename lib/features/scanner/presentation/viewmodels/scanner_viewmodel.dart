import 'package:flutter/foundation.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../../alacena/domain/failures/barcode_scan_failure.dart';
import '../../../diario/data/repositories/meal_health_repository_impl.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../../diario/domain/entities/comida_item.dart';
import '../../../diario/domain/entities/meal_health_evaluation.dart';
import '../../../diario/domain/usecases/evaluate_meal_health_usecase.dart';
import '../../../diario/domain/usecases/health_score_failure_mapper.dart';
import '../../../diario/presentation/viewmodels/health_score_eval_state.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/entities/plato_detectado.dart';
import '../../domain/failures/scanner_failure.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/services/image_capture_service.dart';
import '../../domain/usecases/build_comida_from_plato_usecase.dart';
import 'scanner_state.dart';

/// Pure-Dart ViewModel driving photo capture, AI dish analysis, pantry matching,
/// on-demand Health Score evaluation, and manual meal assembly.
class ScannerViewModel extends ChangeNotifier {
  final ScannerRepository repository;
  final ImageCaptureService? imageCaptureService;
  final BuildComidaFromPlatoUseCase _buildComidaUseCase;
  final EvaluateMealHealthUseCase _evaluateMealHealthUseCase;

  ScannerState _state = const ScannerIdle();
  bool _preferirAlacena = true;
  bool _disposed = false;

  ScannerViewModel({
    required this.repository,
    this.imageCaptureService,
    BuildComidaFromPlatoUseCase? buildComidaUseCase,
    EvaluateMealHealthUseCase? evaluateMealHealthUseCase,
  }) : _buildComidaUseCase =
           buildComidaUseCase ?? BuildComidaFromPlatoUseCase(),
       _evaluateMealHealthUseCase =
           evaluateMealHealthUseCase ??
           EvaluateMealHealthUseCase(repository: MealHealthRepositoryImpl());

  ScannerState get state => _state;
  bool get preferirAlacena => _preferirAlacena;
  bool get isBusy => _state is ScannerCapturing || _state is ScannerAnalyzing;

  ImagenPlato? get imagenActual => switch (_state) {
    ScannerAnalyzing(:final imagen) => imagen,
    ScannerSuccess(:final imagen) => imagen,
    ScannerError(:final imagen) => imagen,
    _ => null,
  };

  PlatoDetectado? get platoActual => switch (_state) {
    ScannerSuccess(:final plato) => plato,
    _ => null,
  };

  HealthScoreSheetSnapshot get healthScoreSnapshot {
    final current = _state;
    if (current is! ScannerSuccess) {
      return const HealthScoreSheetSnapshot(
        healthScore: null,
        razonHealthScore: null,
        isStale: false,
        hasIngredients: false,
        evalState: HealthScoreEvalIdle(),
      );
    }
    return HealthScoreSheetSnapshot(
      healthScore: current.plato.healthScore,
      razonHealthScore: current.plato.explicacionHealthScore,
      isStale: current.healthScoreDesactualizado,
      hasIngredients: current.plato.ingredientes.isNotEmpty,
      evalState: current.healthScoreEvalState,
    );
  }

  void setPreferirAlacena(bool val) {
    if (isBusy || _disposed || _preferirAlacena == val) return;
    _preferirAlacena = val;
    _notifySafe();
  }

  /// Captures a photo via [liveCapture] (if provided) or falls back to
  /// [imageCaptureService.capturarConCamara], then analyzes it with AI.
  Future<bool> capturarYAnalizar({
    required List<IngredienteAlacena> alacenaUsuario,
    Future<ImagenPlato?> Function()? liveCapture,
  }) {
    return _captureAndAnalyze(
      alacenaUsuario: alacenaUsuario,
      capture: () async {
        if (liveCapture != null) {
          final liveImage = await liveCapture();
          if (liveImage != null) return liveImage;
        }
        return imageCaptureService?.capturarConCamara();
      },
    );
  }

  /// Picks an image from the gallery and runs AI dish analysis.
  Future<bool> seleccionarGaleriaYAnalizar({
    required List<IngredienteAlacena> alacenaUsuario,
  }) {
    return _captureAndAnalyze(
      alacenaUsuario: alacenaUsuario,
      capture: () async => imageCaptureService?.seleccionarDeGaleria(),
    );
  }

  Future<bool> _captureAndAnalyze({
    required List<IngredienteAlacena> alacenaUsuario,
    required Future<ImagenPlato?> Function() capture,
  }) async {
    if (isBusy || _disposed) return false;

    _state = const ScannerCapturing();
    _notifySafe();

    try {
      final img = await capture();
      if (_disposed) return false;

      if (img == null) {
        _state = const ScannerIdle();
        _notifySafe();
        return false;
      }

      return _analyzeImage(img, alacenaUsuario);
    } on ScannerFailure catch (failure) {
      if (_disposed) return false;
      _state = _mapFailure(failure, imagen: null);
      _notifySafe();
      return false;
    } on BarcodePermisoDenegadoFailure catch (failure) {
      if (_disposed) return false;
      _state = _mapPermissionFailure(esCamara: failure.esCamara, imagen: null);
      _notifySafe();
      return false;
    } catch (_) {
      if (_disposed) return false;
      _state = const ScannerError(
        message: 'No pudimos procesar la comida. Intentá nuevamente.',
        type: ScannerErrorType.unknown,
      );
      _notifySafe();
      return false;
    }
  }

  /// Re-runs AI analysis using the photo retained inside [ScannerError].
  Future<bool> reintentarAnalisis({
    required List<IngredienteAlacena> alacenaUsuario,
  }) async {
    if (isBusy || _disposed) return false;
    final current = _state;
    if (current is ScannerError && current.imagen != null) {
      return _analyzeImage(current.imagen!, alacenaUsuario);
    }
    if (current is! ScannerIdle) {
      _state = const ScannerIdle();
      _notifySafe();
    }
    return false;
  }

  Future<bool> _analyzeImage(
    ImagenPlato imagen,
    List<IngredienteAlacena> alacenaUsuario,
  ) async {
    _state = ScannerAnalyzing(imagen: imagen);
    _notifySafe();

    try {
      final plato = await repository.escanearPlato(
        imagen: imagen,
        preferirAlacena: _preferirAlacena,
        alacenaUsuario: alacenaUsuario,
      );
      if (_disposed) return false;

      _state = ScannerSuccess(plato: plato, imagen: imagen, esManual: false);
      _notifySafe();
      return true;
    } on ScannerFailure catch (failure) {
      if (_disposed) return false;
      _state = _mapFailure(failure, imagen: imagen);
      _notifySafe();
      return false;
    } on BarcodePermisoDenegadoFailure catch (failure) {
      if (_disposed) return false;
      _state = _mapPermissionFailure(
        esCamara: failure.esCamara,
        imagen: imagen,
      );
      _notifySafe();
      return false;
    } catch (_) {
      if (_disposed) return false;
      _state = ScannerError(
        message: 'No pudimos procesar la comida. Intentá nuevamente.',
        type: ScannerErrorType.unknown,
        imagen: imagen,
      );
      _notifySafe();
      return false;
    }
  }

  /// Opens a photo-free manual meal draft so the user can pick pantry ingredients.
  bool iniciarComidaManual() {
    if (isBusy || _disposed) return false;
    _state = ScannerSuccess(
      plato: PlatoDetectado.manualEmpty(),
      imagen: null,
      esManual: true,
    );
    _notifySafe();
    return true;
  }

  /// Evaluates or refreshes the active dish's Health Score on demand via Gemini.
  ///
  /// Drops stale responses if the dish is replaced or edited while in flight.
  Future<bool> evaluarHealthScore({String? titulo}) async {
    final current = _state;
    if (_disposed ||
        current is! ScannerSuccess ||
        current.healthScoreEvalState is HealthScoreEvaluating ||
        current.plato.ingredientes.isEmpty) {
      return false;
    }

    final platoId = current.plato.id;
    final input = MealHealthEvaluationInput.fromPlatoDetectado(
      current.plato,
      tituloOverride: titulo,
    );
    final fingerprint = input.computeFingerprint();

    _state = current.copyWith(
      healthScoreEvalState: const HealthScoreEvaluating(),
    );
    _notifySafe();

    final result = await _evaluateMealHealthUseCase(input);
    if (_disposed) return false;

    final latest = _state;
    if (latest is! ScannerSuccess || latest.plato.id != platoId) {
      return false;
    }

    final latestFingerprint = MealHealthEvaluationInput.fromPlatoDetectado(
      latest.plato,
      tituloOverride: titulo,
    ).computeFingerprint();
    if (latestFingerprint != fingerprint) {
      _state = latest.copyWith(
        healthScoreEvalState: const HealthScoreEvalIdle(),
      );
      _notifySafe();
      return false;
    }

    switch (result) {
      case MealHealthSuccess(:final evaluation):
        _state = latest.copyWith(
          plato: latest.plato.copyWith(
            healthScore: evaluation.healthScore,
            explicacionHealthScore: evaluation.razonHealthScore,
          ),
          healthScoreDesactualizado: false,
          healthScoreEvalState: HealthScoreEvalSuccess(
            healthScore: evaluation.healthScore,
            razonHealthScore: evaluation.razonHealthScore,
          ),
        );
        _notifySafe();
        return true;
      case MealHealthError(:final failure):
        final mapped = HealthScoreFailureMapper.map(failure);
        _state = latest.copyWith(
          healthScoreEvalState: HealthScoreEvalError(
            message: mapped.message,
            type: mapped.type,
          ),
        );
        _notifySafe();
        return false;
    }
  }

  /// Resolves a brand ambiguity by replacing the generic match with [alacenaElegida].
  void resolverConflictoMarca({
    required String nombreGenerico,
    required IngredienteAlacena alacenaElegida,
  }) {
    final current = _state;
    if (_disposed || current is! ScannerSuccess) return;

    final plato = current.plato;
    final index = plato.ingredientes.indexWhere(
      (i) => i.nombre.toLowerCase().contains(nombreGenerico.toLowerCase()),
    );
    if (index == -1) return;

    final existing = plato.ingredientes[index];
    final replacement = ComidaIngrediente.desdeAlacena(
      alacena: alacenaElegida,
      gramos: existing.gramos,
    );

    final updatedIngredients = List<ComidaIngrediente>.from(plato.ingredientes);
    updatedIngredients[index] = replacement;

    final remainingConflicts = plato.conflictosMarcas
        .where((c) => c.nombreGenerico != nombreGenerico)
        .toList();

    _state = current.copyWith(
      plato: plato.copyWith(
        ingredientes: List.unmodifiable(updatedIngredients),
        conflictosMarcas: List.unmodifiable(remainingConflicts),
      ),
      healthScoreDesactualizado: plato.healthScore != null,
      healthScoreEvalState: const HealthScoreEvalIdle(),
    );
    _notifySafe();
  }

  void ajustarGramosIngrediente(String id, double delta) {
    final current = _state;
    if (_disposed || current is! ScannerSuccess) return;

    final plato = current.plato;
    final index = plato.ingredientes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = plato.ingredientes[index];
    final nextGrams = (item.gramos + delta).clamp(5.0, 1000.0);
    if (nextGrams == item.gramos) return;

    final updatedIngredients = List<ComidaIngrediente>.from(plato.ingredientes);
    updatedIngredients[index] = item.conGramos(nextGrams);

    _state = current.copyWith(
      plato: plato.copyWith(
        ingredientes: List.unmodifiable(updatedIngredients),
      ),
      healthScoreDesactualizado: plato.healthScore != null,
      healthScoreEvalState: const HealthScoreEvalIdle(),
    );
    _notifySafe();
  }

  void fijarGramosIngrediente(String id, double gramos) {
    final current = _state;
    if (_disposed || current is! ScannerSuccess) return;

    final plato = current.plato;
    final index = plato.ingredientes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = plato.ingredientes[index];
    final clampedGrams = gramos.clamp(5.0, 1000.0);
    if (clampedGrams == item.gramos) return;

    final updatedIngredients = List<ComidaIngrediente>.from(plato.ingredientes);
    updatedIngredients[index] = item.conGramos(clampedGrams);

    _state = current.copyWith(
      plato: plato.copyWith(
        ingredientes: List.unmodifiable(updatedIngredients),
      ),
      healthScoreDesactualizado: plato.healthScore != null,
      healthScoreEvalState: const HealthScoreEvalIdle(),
    );
    _notifySafe();
  }

  void eliminarIngrediente(String id) {
    final current = _state;
    if (_disposed || current is! ScannerSuccess) return;

    final plato = current.plato;
    final updatedIngredients = plato.ingredientes
        .where((i) => i.id != id)
        .toList();
    if (updatedIngredients.length == plato.ingredientes.length) return;

    _state = current.copyWith(
      plato: plato.copyWith(
        ingredientes: List.unmodifiable(updatedIngredients),
      ),
      healthScoreDesactualizado: plato.healthScore != null,
      healthScoreEvalState: const HealthScoreEvalIdle(),
    );
    _notifySafe();
  }

  void agregarIngredienteDesdeAlacena(
    IngredienteAlacena alacena,
    double gramos,
  ) {
    final current = _state;
    if (_disposed || current is! ScannerSuccess) return;

    final plato = current.plato;
    final added = ComidaIngrediente.desdeAlacena(
      alacena: alacena,
      gramos: gramos,
    );

    _state = current.copyWith(
      plato: plato.copyWith(
        ingredientes: List.unmodifiable([...plato.ingredientes, added]),
      ),
      healthScoreDesactualizado: plato.healthScore != null,
      healthScoreEvalState: const HealthScoreEvalIdle(),
    );
    _notifySafe();
  }

  /// Builds a [ComidaItem] for the diary when in [ScannerSuccess] with >= 1 ingredient.
  ComidaItem? construirComidaParaDiario({
    required String titulo,
    required String tipoComida,
    DateTime? now,
  }) {
    final current = _state;
    if (current is! ScannerSuccess || current.plato.ingredientes.isEmpty) {
      return null;
    }

    return _buildComidaUseCase(
      plato: current.plato,
      titulo: titulo,
      tipoComida: tipoComida,
      healthScoreDesactualizado: current.healthScoreDesactualizado,
      now: now,
    );
  }

  void descartarError() {
    if (_disposed || _state is! ScannerError) return;
    _state = const ScannerIdle();
    _notifySafe();
  }

  void reiniciar() {
    if (_disposed || _state is ScannerIdle) return;
    _state = const ScannerIdle();
    _notifySafe();
  }

  ScannerError _mapPermissionFailure({
    required bool esCamara,
    required ImagenPlato? imagen,
  }) {
    return ScannerError(
      message: esCamara
          ? 'Necesitamos permiso de cámara para escanear el plato.'
          : 'Necesitamos permiso de galería para elegir una foto.',
      type: ScannerErrorType.permissionDenied,
      imagen: imagen,
    );
  }

  ScannerError _mapFailure(
    ScannerFailure failure, {
    required ImagenPlato? imagen,
  }) {
    return switch (failure) {
      ScannerApiKeyMissingFailure() => ScannerError(
        message:
            'La función con IA requiere configurar GEMINI_API_KEY en este entorno.',
        type: ScannerErrorType.missingApiKey,
        imagen: imagen,
      ),
      ScannerMissingImageFailure() => ScannerError(
        message: 'No se recibió ninguna imagen para analizar.',
        type: ScannerErrorType.invalidImage,
        imagen: imagen,
      ),
      ScannerInvalidImageFailure(:final reason) => ScannerError(
        message: switch (reason) {
          'empty' => 'La imagen seleccionada está vacía.',
          'size_exceeded' => 'La imagen supera el máximo permitido de 15 MB.',
          'unsupported_mime' =>
            'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.',
          _ => 'La imagen seleccionada no es válida.',
        },
        type: ScannerErrorType.invalidImage,
        imagen: imagen,
      ),
      ScannerPermissionDeniedFailure(:final isCamera) => _mapPermissionFailure(
        esCamara: isCamera,
        imagen: imagen,
      ),
      ScannerNetworkFailure() => ScannerError(
        message:
            'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.',
        type: ScannerErrorType.network,
        imagen: imagen,
      ),
      ScannerTimeoutFailure() => ScannerError(
        message:
            'El análisis tardó demasiado. Intentá nuevamente en unos segundos.',
        type: ScannerErrorType.timeout,
        imagen: imagen,
      ),
      ScannerRateLimitFailure() => ScannerError(
        message:
            'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.',
        type: ScannerErrorType.rateLimit,
        imagen: imagen,
      ),
      ScannerServiceUnavailableFailure() => ScannerError(
        message:
            'El servicio de análisis no está disponible en este momento. Probá más tarde.',
        type: ScannerErrorType.serviceUnavailable,
        imagen: imagen,
      ),
      ScannerInvalidResponseFailure() => ScannerError(
        message:
            'No pudimos interpretar la respuesta de la IA. Intentá con otra foto.',
        type: ScannerErrorType.invalidResponse,
        imagen: imagen,
      ),
      ScannerNoFoodDetectedFailure() => ScannerError(
        message:
            'No pudimos reconocer alimentos en la foto. Probá más de cerca o con mejor luz.',
        type: ScannerErrorType.noFoodDetected,
        imagen: imagen,
      ),
      ScannerEmptyIngredientsFailure() => ScannerError(
        message:
            'Agregá al menos un ingrediente para calcular el Health Score.',
        type: ScannerErrorType.noFoodDetected,
        imagen: imagen,
      ),
    };
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
