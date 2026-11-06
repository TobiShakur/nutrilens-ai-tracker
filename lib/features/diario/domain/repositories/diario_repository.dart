import '../entities/comida_item.dart';
import '../entities/diario_dia.dart';

abstract class DiarioRepository {
  /// Retorna el mapa de 7 días (0 a 6) con datos iniciales realistas o persistidos.
  Map<int, DiarioDia> getDiasIniciales();

  /// Guarda el estado de los días de la semana en el almacenamiento local.
  Future<void> guardarDias(Map<int, DiarioDia> dias);

  /// Genera una nueva comida aleatoria con macros y calorías reales
  ComidaItem generarComidaAleatoria(int numeroComida);
}
