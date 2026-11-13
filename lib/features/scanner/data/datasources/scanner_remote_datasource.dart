import '../../../diario/data/models/meal_health_evaluation_model.dart';
import '../../../diario/domain/entities/meal_health_evaluation.dart';
import '../../domain/entities/imagen_plato.dart';
import '../models/plato_detectado_model.dart';

/// Contract for remote AI operations (Gemini Vision & text Health Score).
abstract class ScannerRemoteDataSource {
  Future<PlatoDetectadoModel> analizarFotoPlato({
    required ImagenPlato imagen,
    required List<String> nombresAlacena,
    String languageCode = 'es',
  });

  Future<MealHealthEvaluationModel> evaluarHealthScore({
    required MealHealthEvaluationInput input,
    String languageCode = 'es',
  });
}
