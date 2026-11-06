// VIEWMODEL DEL INVENTARIO DE ALACENA (PATRÓN MVVM)
// Administra el catálogo de ingredientes, categorías personalizadas, filtrado en tiempo real,
// validaciones de negocio con AlacenaResult y vinculación con el escáner de visión artificial.

import 'package:flutter/foundation.dart';
import '../../domain/entities/categoria_alacena.dart';
import '../../domain/entities/ingrediente_alacena.dart';
import '../../domain/repositories/alacena_repository.dart';
import '../../domain/results/alacena_result.dart';

class AlacenaViewModel extends ChangeNotifier {
  final AlacenaRepository repository;

  bool _cargando = false;
  List<IngredienteAlacena> _ingredientes = [];
  final List<CategoriaAlacena> _categorias = List.of(
    CategoriaAlacena.predeterminadas,
  );
  CategoriaAlacena _categoriaSeleccionada = CategoriaAlacena.todos;
  String _busquedaQuery = '';
  int _contadorSecuencia = 100;

  AlacenaViewModel({required this.repository}) {
    cargar();
  }

  bool get cargando => _cargando;
  List<CategoriaAlacena> get categorias => List.unmodifiable(_categorias);
  CategoriaAlacena get categoriaSeleccionada => _categoriaSeleccionada;
  String get busquedaQuery => _busquedaQuery;
  int get totalIngredientes => _ingredientes.length;
  List<IngredienteAlacena> get todosLosIngredientes =>
      List.unmodifiable(_ingredientes);

  List<IngredienteAlacena> get ingredientesFiltrados {
    return _ingredientes.where((item) {
      final coincideCategoria =
          _categoriaSeleccionada == CategoriaAlacena.todos ||
          item.categoria == _categoriaSeleccionada;

      final query = _busquedaQuery.trim().toLowerCase();
      final coincideBusqueda =
          query.isEmpty ||
          item.nombre.toLowerCase().contains(query) ||
          (item.marca?.toLowerCase().contains(query) ?? false);

      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();

    final items = await repository.obtenerIngredientes();
    _ingredientes = List.of(items);
    _cargando = false;
    notifyListeners();
  }

  void seleccionarCategoria(CategoriaAlacena categoria) {
    if (_categoriaSeleccionada == categoria) return;
    _categoriaSeleccionada = categoria;
    notifyListeners();
  }

  CategoriaAlacena agregarCategoria(String label, [String emoji = '🏷️']) {
    final limpio = label.trim();
    if (limpio.isEmpty) return _categoriaSeleccionada;

    final id = 'cat_${limpio.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final existente = _categorias.where((c) => c.id == id).firstOrNull;
    if (existente != null) {
      _categoriaSeleccionada = existente;
      notifyListeners();
      return existente;
    }

    final nueva = CategoriaAlacena(id: id, label: limpio, emoji: emoji);
    final indexOtros = _categorias.indexWhere((c) => c.id == 'otros');
    if (indexOtros != -1) {
      _categorias.insert(indexOtros, nueva);
    } else {
      _categorias.add(nueva);
    }
    _categoriaSeleccionada = nueva;
    notifyListeners();
    return nueva;
  }

  bool editarCategoria(
    String id, {
    required String nuevoNombre,
    required String nuevoEmoji,
  }) {
    if (id == 'todos') return false;
    final index = _categorias.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final limpia = nuevoNombre.trim();
    if (limpia.isEmpty) return false;

    final emojiFinal = nuevoEmoji.trim().isEmpty ? '🏷️' : nuevoEmoji.trim();
    final actualizada = CategoriaAlacena(
      id: id,
      label: limpia,
      emoji: emojiFinal,
    );
    _categorias[index] = actualizada;

    // Actualizamos los ingredientes que tenían esta categoría
    for (var i = 0; i < _ingredientes.length; i++) {
      if (_ingredientes[i].categoria.id == id) {
        _ingredientes[i] = _ingredientes[i].copyWith(categoria: actualizada);
      }
    }

    if (_categoriaSeleccionada.id == id) {
      _categoriaSeleccionada = actualizada;
    }

    notifyListeners();
    return true;
  }

  bool eliminarCategoria(String id) {
    if (id == 'todos') return false;
    final index = _categorias.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    _categorias.removeAt(index);

    // Reasignamos los ingredientes huérfanos a "Otros"
    const categoriaFallback = CategoriaAlacena.otros;
    for (var i = 0; i < _ingredientes.length; i++) {
      if (_ingredientes[i].categoria.id == id) {
        _ingredientes[i] = _ingredientes[i].copyWith(
          categoria: categoriaFallback,
        );
      }
    }

    if (_categoriaSeleccionada.id == id) {
      _categoriaSeleccionada = CategoriaAlacena.todos;
    }

    notifyListeners();
    return true;
  }

  void actualizarBusqueda(String query) {
    if (_busquedaQuery == query) return;
    _busquedaQuery = query;
    notifyListeners();
  }

  Future<AlacenaResult<IngredienteAlacena>> crearIngrediente({
    required String nombre,
    String? marca,
    required CategoriaAlacena categoria,
    double gramosPorcion = 100.0,
    required int calorias,
    required double proteinas,
    required double carbohidratos,
    required double grasas,
  }) async {
    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      return const AlacenaFallo('El nombre del ingrediente es obligatorio.');
    }

    if (categoria == CategoriaAlacena.todos) {
      return const AlacenaFallo('Seleccioná una categoría nutricional válida.');
    }

    if (gramosPorcion <= 0) {
      return const AlacenaFallo(
        'El tamaño de porción debe ser mayor a 0 gramos.',
      );
    }

    if (calorias < 0) {
      return const AlacenaFallo('Las calorías no pueden ser negativas.');
    }

    if (proteinas < 0 || carbohidratos < 0 || grasas < 0) {
      return const AlacenaFallo(
        'Los macros no pueden tener valores negativos.',
      );
    }

    _contadorSecuencia++;
    final nuevo = IngredienteAlacena(
      id: 'ing_${DateTime.now().microsecondsSinceEpoch}_$_contadorSecuencia',
      nombre: nombreLimpio,
      marca: marca?.trim().isEmpty ?? true ? null : marca!.trim(),
      categoria: categoria,
      gramosPorcion: gramosPorcion,
      calorias: calorias,
      proteinas: proteinas,
      carbohidratos: carbohidratos,
      grasas: grasas,
      creadoEn: DateTime.now(),
    );

    await repository.agregarIngrediente(nuevo);
    _ingredientes.insert(0, nuevo);
    notifyListeners();

    return AlacenaExito(nuevo);
  }

  Future<AlacenaResult<IngredienteAlacena>> editarIngrediente({
    required String id,
    required String nombre,
    String? marca,
    required CategoriaAlacena categoria,
    double gramosPorcion = 100.0,
    required int calorias,
    required double proteinas,
    required double carbohidratos,
    required double grasas,
  }) async {
    final index = _ingredientes.indexWhere((i) => i.id == id);
    if (index == -1) {
      return const AlacenaFallo(
        'No se encontró el ingrediente para modificar.',
      );
    }

    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      return const AlacenaFallo('El nombre del ingrediente es obligatorio.');
    }

    if (categoria == CategoriaAlacena.todos) {
      return const AlacenaFallo('Seleccioná una categoría nutricional válida.');
    }

    if (gramosPorcion <= 0) {
      return const AlacenaFallo(
        'El tamaño de porción debe ser mayor a 0 gramos.',
      );
    }

    if (calorias < 0) {
      return const AlacenaFallo('Las calorías no pueden ser negativas.');
    }

    if (proteinas < 0 || carbohidratos < 0 || grasas < 0) {
      return const AlacenaFallo(
        'Los macros no pueden tener valores negativos.',
      );
    }

    final actual = _ingredientes[index];
    final actualizado = actual.copyWith(
      nombre: nombreLimpio,
      marca: marca?.trim().isEmpty ?? true ? null : marca!.trim(),
      categoria: categoria,
      gramosPorcion: gramosPorcion,
      calorias: calorias,
      proteinas: proteinas,
      carbohidratos: carbohidratos,
      grasas: grasas,
    );

    await repository.actualizarIngrediente(actualizado);
    _ingredientes[index] = actualizado;
    notifyListeners();

    return AlacenaExito(actualizado);
  }

  Future<AlacenaResult<void>> borrarIngrediente(String id) async {
    final eliminado = await repository.eliminarIngrediente(id);
    if (!eliminado) {
      return const AlacenaFallo('No se encontró el ingrediente para eliminar.');
    }

    _ingredientes.removeWhere((item) => item.id == id);
    notifyListeners();
    return const AlacenaExito(null);
  }
}
