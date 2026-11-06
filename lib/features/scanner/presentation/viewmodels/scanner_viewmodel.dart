// VIEWMODEL DE RECONOCIMIENTO VISUAL Y MATCHING DE ALACENA (PATRÓN MVVM)
// Orquesta la captura/selección de imágenes, el análisis multimodal con Gemini Vision
// y el cruce automático con los ingredientes registrados en la alacena del usuario.

import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/entities/plato_detectado.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/services/image_capture_service.dart';

class ScannerViewModel extends ChangeNotifier {
  final ScannerRepository repository;
  final ImageCaptureService? imageCaptureService;

  bool _preferirAlacena = true;
  bool _escaneando = false;
  bool _capturandoFoto = false;
  ImagenPlato? _fotoCapturada;
  PlatoDetectado? _platoDetectado;
  String? _error;

  ScannerViewModel({required this.repository, this.imageCaptureService});

  bool get preferirAlacena => _preferirAlacena;
  bool get escaneando => _escaneando;
  bool get capturandoFoto => _capturandoFoto;
  ImagenPlato? get fotoCapturada => _fotoCapturada;
  PlatoDetectado? get platoDetectado => _platoDetectado;
  String? get error => _error;
  bool get hayPlatoDetectado => _platoDetectado != null;

  void setPreferirAlacena(bool valor) {
    if (_preferirAlacena == valor) return;
    _preferirAlacena = valor;
    notifyListeners();
  }

  void togglePreferirAlacena() {
    _preferirAlacena = !_preferirAlacena;
    notifyListeners();
  }

  Future<ImagenPlato?> capturarFotoConCamara() async {
    if (imageCaptureService == null) return null;
    _capturandoFoto = true;
    _error = null;
    notifyListeners();

    try {
      final img = await imageCaptureService!.capturarConCamara();
      _fotoCapturada = img;
      _capturandoFoto = false;
      notifyListeners();
      return img;
    } catch (e) {
      _capturandoFoto = false;
      _error = 'No se pudo acceder a la cámara.';
      notifyListeners();
      return null;
    }
  }

  Future<ImagenPlato?> seleccionarFotoDeGaleria() async {
    if (imageCaptureService == null) return null;
    _capturandoFoto = true;
    _error = null;
    notifyListeners();

    try {
      final img = await imageCaptureService!.seleccionarDeGaleria();
      _fotoCapturada = img;
      _capturandoFoto = false;
      notifyListeners();
      return img;
    } catch (e) {
      _capturandoFoto = false;
      _error = 'No se pudo acceder a la galería.';
      notifyListeners();
      return null;
    }
  }

  void establecerFotoCapturada(ImagenPlato imagen) {
    _fotoCapturada = imagen;
    notifyListeners();
  }

  void descartarFotoCapturada() {
    _fotoCapturada = null;
    notifyListeners();
  }

  Future<PlatoDetectado?> escanear(
    List<IngredienteAlacena> alacenaUsuario, {
    ImagenPlato? imagen,
  }) async {
    _escaneando = true;
    _error = null;
    notifyListeners();

    try {
      final resultado = await repository.escanearPlato(
        imagen: imagen ?? _fotoCapturada,
        preferirAlacena: _preferirAlacena,
        alacenaUsuario: alacenaUsuario,
      );
      _platoDetectado = resultado;
      _escaneando = false;
      notifyListeners();
      return resultado;
    } catch (e) {
      if (!ApiConstants.tieneGeminiApiKey) {
        _error =
            'Configurá tu GEMINI_API_KEY para escanear alimentos con IA (--dart-define=GEMINI_API_KEY=tu_clave).';
      } else {
        _error = 'Ocurrió un error al procesar el plato: $e';
      }
      _escaneando = false;
      notifyListeners();
      return null;
    }
  }

  /// Resuelve una ambigüedad reemplazando el ingrediente con la marca seleccionada por el usuario
  void resolverConflictoMarca({
    required String nombreGenerico,
    required IngredienteAlacena alacenaElegida,
  }) {
    if (_platoDetectado == null) return;
    final plato = _platoDetectado!;

    final index = plato.ingredientes.indexWhere(
      (i) => i.nombre.toLowerCase().contains(nombreGenerico.toLowerCase()),
    );
    if (index == -1) return;

    final actual = plato.ingredientes[index];
    final reemplazado = ComidaIngrediente.desdeAlacena(
      alacena: alacenaElegida,
      gramos: actual.gramos,
    );

    final nuevaLista = List<ComidaIngrediente>.from(plato.ingredientes);
    nuevaLista[index] = reemplazado;

    final nuevosConflictos = plato.conflictosMarcas
        .where((c) => c.nombreGenerico != nombreGenerico)
        .toList();

    _platoDetectado = plato.copyWith(
      ingredientes: nuevaLista,
      conflictosMarcas: nuevosConflictos,
    );
    notifyListeners();
  }

  void ajustarGramosIngrediente(String id, double delta) {
    if (_platoDetectado == null) return;
    final plato = _platoDetectado!;
    final index = plato.ingredientes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = plato.ingredientes[index];
    final nuevosGramos = (item.gramos + delta).clamp(5.0, 1000.0);
    final nuevaLista = List<ComidaIngrediente>.from(plato.ingredientes);
    nuevaLista[index] = item.conGramos(nuevosGramos);

    _platoDetectado = plato.copyWith(ingredientes: nuevaLista);
    notifyListeners();
  }

  void fijarGramosIngrediente(String id, double gramos) {
    if (_platoDetectado == null) return;
    final plato = _platoDetectado!;
    final index = plato.ingredientes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = plato.ingredientes[index];
    final nuevaLista = List<ComidaIngrediente>.from(plato.ingredientes);
    nuevaLista[index] = item.conGramos(gramos.clamp(5.0, 1000.0));

    _platoDetectado = plato.copyWith(ingredientes: nuevaLista);
    notifyListeners();
  }

  void eliminarIngrediente(String id) {
    if (_platoDetectado == null) return;
    final plato = _platoDetectado!;
    final nuevaLista = plato.ingredientes.where((i) => i.id != id).toList();

    _platoDetectado = plato.copyWith(ingredientes: nuevaLista);
    notifyListeners();
  }

  void agregarIngredienteDesdeAlacena(
    IngredienteAlacena alacena,
    double gramos,
  ) {
    if (_platoDetectado == null) return;
    final plato = _platoDetectado!;
    final nuevo = ComidaIngrediente.desdeAlacena(
      alacena: alacena,
      gramos: gramos,
    );

    _platoDetectado = plato.copyWith(
      ingredientes: [...plato.ingredientes, nuevo],
    );
    notifyListeners();
  }

  void reiniciar() {
    _platoDetectado = null;
    _fotoCapturada = null;
    _error = null;
    _escaneando = false;
    _capturandoFoto = false;
    notifyListeners();
  }
}
