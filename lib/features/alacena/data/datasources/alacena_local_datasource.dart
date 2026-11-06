// DATA SOURCE LOCAL DE ALACENA CON PERSISTENCIA Y SEMILLA INICIAL
// Maneja la colección en memoria y persiste los ingredientes de la alacena en LocalStorageService.

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/categoria_alacena.dart';
import '../../domain/entities/ingrediente_alacena.dart';

abstract class AlacenaLocalDataSource {
  Future<List<IngredienteAlacena>> getIngredientes();
  Future<IngredienteAlacena> saveIngrediente(IngredienteAlacena ingrediente);
  Future<bool> deleteIngrediente(String id);
}

class AlacenaLocalDataSourceImpl implements AlacenaLocalDataSource {
  final LocalStorageService? storageService;
  final List<IngredienteAlacena> _items = [];

  AlacenaLocalDataSourceImpl({this.storageService}) {
    final guardado = storageService?.obtenerAlacena();
    if (guardado != null && guardado.isNotEmpty) {
      _items.addAll(guardado);
    } else {
      _sembrarIniciales();
      storageService?.guardarAlacena(_items);
    }
  }

  void _sembrarIniciales() {
    final ahora = DateTime.now();
    _items.addAll([
      IngredienteAlacena(
        id: 'ing_1',
        nombre: 'Huevos de campo',
        marca: null,
        categoria: CategoriaAlacena.proteinas,
        gramosPorcion: 100.0,
        calorias: 143,
        proteinas: 13.0,
        carbohidratos: 1.0,
        grasas: 10.0,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_2',
        nombre: 'Avena tradicional',
        marca: 'Quáker',
        categoria: CategoriaAlacena.carbohidratos,
        gramosPorcion: 100.0,
        calorias: 370,
        proteinas: 14.0,
        carbohidratos: 60.0,
        grasas: 7.0,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_3',
        nombre: 'Pechuga de pollo',
        marca: null,
        categoria: CategoriaAlacena.proteinas,
        gramosPorcion: 100.0,
        calorias: 165,
        proteinas: 31.0,
        carbohidratos: 0.0,
        grasas: 3.6,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_4',
        nombre: 'Pan integral 100%',
        marca: 'Fargo',
        categoria: CategoriaAlacena.carbohidratos,
        gramosPorcion: 50.0, // 2 rebanadas típicas
        calorias: 120,
        proteinas: 4.5,
        carbohidratos: 22.0,
        grasas: 1.5,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_5',
        nombre: 'Palta Hass',
        marca: null,
        categoria: CategoriaAlacena.grasas,
        gramosPorcion: 100.0,
        calorias: 160,
        proteinas: 2.0,
        carbohidratos: 8.5,
        grasas: 15.0,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_6',
        nombre: 'Arroz integral',
        marca: 'Gallo',
        categoria: CategoriaAlacena.carbohidratos,
        gramosPorcion: 100.0,
        calorias: 350,
        proteinas: 7.5,
        carbohidratos: 73.0,
        grasas: 2.8,
        creadoEn: ahora,
      ),
      IngredienteAlacena(
        id: 'ing_7',
        nombre: 'Queso untable light',
        marca: 'Finlandia',
        categoria: CategoriaAlacena.lacteos,
        gramosPorcion: 30.0, // 1 cucharada sopera típica
        calorias: 29,
        proteinas: 2.6,
        carbohidratos: 1.2,
        grasas: 1.5,
        creadoEn: ahora,
      ),
    ]);
  }

  @override
  Future<List<IngredienteAlacena>> getIngredientes() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<IngredienteAlacena> saveIngrediente(
    IngredienteAlacena ingrediente,
  ) async {
    _items.removeWhere((item) => item.id == ingrediente.id);
    _items.insert(0, ingrediente);
    await storageService?.guardarAlacena(_items);
    return ingrediente;
  }

  @override
  Future<bool> deleteIngrediente(String id) async {
    final inicial = _items.length;
    _items.removeWhere((item) => item.id == id);
    final borrado = _items.length < inicial;
    if (borrado) {
      await storageService?.guardarAlacena(_items);
    }
    return borrado;
  }
}
