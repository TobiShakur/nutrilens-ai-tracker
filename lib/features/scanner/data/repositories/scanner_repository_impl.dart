import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/entities/plato_detectado.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/usecases/match_pantry_ingredients_usecase.dart';
import '../datasources/scanner_firebase_ai_datasource.dart';
import '../datasources/scanner_remote_datasource.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  final ScannerRemoteDataSource _remoteDataSource;
  final MatchPantryIngredientsUseCase _matchPantryUseCase;

  ScannerRepositoryImpl({
    ScannerRemoteDataSource? remoteDataSource,
    MatchPantryIngredientsUseCase? matchPantryUseCase,
  }) : _remoteDataSource =
           remoteDataSource ?? ScannerFirebaseAiDataSourceImpl(),
       _matchPantryUseCase =
           matchPantryUseCase ?? MatchPantryIngredientsUseCase();

  @override
  Future<PlatoDetectado> escanearPlato({
    required ImagenPlato imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  }) async {
    final model = await _remoteDataSource.analizarFotoPlato(
      imagen: imagen,
      nombresAlacena: alacenaUsuario.map((a) => a.nombre).toList(),
    );

    final rawIngredients = model.ingredientes
        .asMap()
        .entries
        .map((e) => e.value.toEntity(id: 'raw_${e.key}'))
        .toList();

    return _matchPantryUseCase(
      dishName: model.nombrePlato,
      healthScore: model.healthScore,
      healthScoreExplanation: model.explicacionHealthScore,
      detectedIngredients: rawIngredients,
      preferirAlacena: preferirAlacena,
      alacenaUsuario: alacenaUsuario,
    );
  }
}
