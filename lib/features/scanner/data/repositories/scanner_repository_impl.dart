import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../domain/entities/alimento_conflicto_marca.dart';
import '../../domain/entities/imagen_plato.dart';
import '../../domain/entities/plato_detectado.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../datasources/scanner_datasource.dart';
import '../datasources/scanner_firebase_ai_datasource.dart';
import '../datasources/scanner_remote_datasource.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  final ScannerRemoteDataSource _remoteDataSource;
  final ScannerDataSource _mockDataSource;

  ScannerRepositoryImpl({
    ScannerRemoteDataSource? remoteDataSource,
    ScannerDataSource? mockDataSource,
  }) : _remoteDataSource =
           remoteDataSource ?? ScannerFirebaseAiDataSourceImpl(),
       _mockDataSource = mockDataSource ?? ScannerDataSourceImpl();

  @override
  Future<PlatoDetectado> escanearPlato({
    ImagenPlato? imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  }) async {
    // Si no hay imagen binaria, usamos el DataSource de simulación previa (retrocompatibilidad)
    if (imagen == null) {
      return _mockDataSource.simularEscaneo(
        preferirAlacena: preferirAlacena,
        alacenaUsuario: alacenaUsuario,
      );
    }

    // Análisis con Firebase AI / Gemini Vision
    final model = await _remoteDataSource.analizarFotoPlato(
      imagen: imagen,
      nombresAlacena: alacenaUsuario.map((a) => a.nombre).toList(),
    );

    final List<ComidaIngrediente> ingredientesFinales = [];
    final List<AlimentoConflictoMarca> conflictos = [];

    for (int i = 0; i < model.ingredientes.length; i++) {
      final ingModel = model.ingredientes[i];
      final nombreBuscado = ingModel.nombre.toLowerCase();

      if (preferirAlacena) {
        final coincidencias = alacenaUsuario.where((al) {
          final n = al.nombre.toLowerCase();
          return n.contains(nombreBuscado) || nombreBuscado.contains(n);
        }).toList();

        if (coincidencias.length == 1) {
          ingredientesFinales.add(
            ComidaIngrediente.desdeAlacena(
              alacena: coincidencias.first,
              gramos: ingModel.gramos,
            ),
          );
          continue;
        } else if (coincidencias.length > 1) {
          conflictos.add(
            AlimentoConflictoMarca(
              nombreGenerico: ingModel.nombre,
              gramosDetectados: ingModel.gramos,
              opcionesAlacena: coincidencias,
            ),
          );
          ingredientesFinales.add(
            ComidaIngrediente.desdeAlacena(
              alacena: coincidencias.first,
              gramos: ingModel.gramos,
            ),
          );
          continue;
        }
      }

      // Si no coincide con la alacena, usamos los datos nutricionales directos de la IA
      ingredientesFinales.add(
        ingModel.toEntity(
          id: 'ci_ai_${DateTime.now().microsecondsSinceEpoch}_$i',
        ),
      );
    }

    return PlatoDetectado(
      id: 'plato_${DateTime.now().microsecondsSinceEpoch}',
      nombreSugerido: model.nombrePlato,
      healthScore: model.healthScore,
      explicacionHealthScore: model.explicacionHealthScore,
      ingredientes: ingredientesFinales,
      conflictosMarcas: conflictos,
    );
  }
}
