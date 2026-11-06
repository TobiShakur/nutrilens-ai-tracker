import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:nutrilens_provider/features/scanner/data/models/comida_ingrediente_model.dart';
import 'package:nutrilens_provider/features/scanner/data/models/plato_detectado_model.dart';
import 'package:nutrilens_provider/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/image_capture_service.dart';
import 'package:nutrilens_provider/features/scanner/presentation/viewmodels/scanner_viewmodel.dart';

class FakeImageCaptureService implements ImageCaptureService {
  final ImagenPlato? resultado;
  FakeImageCaptureService({this.resultado});

  @override
  Future<ImagenPlato?> capturarConCamara() async => resultado;

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() async => resultado;
}

class FakeScannerRemoteDataSource implements ScannerRemoteDataSource {
  final bool fallar;
  FakeScannerRemoteDataSource({this.fallar = false});

  @override
  Future<PlatoDetectadoModel> analizarFotoPlato({
    required ImagenPlato imagen,
    required List<String> nombresAlacena,
  }) async {
    if (fallar) {
      throw Exception('Fallo de conexión o imagen borrosa.');
    }
    return const PlatoDetectadoModel(
      nombrePlato: 'Huevos revueltos con tostadas',
      healthScore: 88,
      ingredientes: [
        ComidaIngredienteModel(
          nombre: 'Huevos de campo',
          gramos: 120,
          calorias: 170,
          proteinas: 15.0,
          carbos: 1.0,
          grasas: 12.0,
          emoji: '🍳',
        ),
      ],
    );
  }
}

void main() {
  group('ImagenPlato Value Object & DTOs de Gemini Vision', () {
    test('ImagenPlato valida bytes no vacíos y calcula tamaño legible', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final imagen = ImagenPlato.crear(bytes: bytes, mimeType: 'image/jpeg');

      expect(imagen.tamanoBytes, 5);
      expect(imagen.tamanoLegible, '5 B');
      expect(imagen.mimeType, 'image/jpeg');

      expect(() => ImagenPlato.crear(bytes: Uint8List(0)), throwsArgumentError);
    });

    test('PlatoDetectadoModel parsea JSON de IA con defensiva ante nulos', () {
      final json = {
        'nombrePlato': 'Bowl de Salmón',
        'healthScore': 95,
        'explicacionHealthScore':
            'Excelente aporte de omega-3 y proteínas magras.',
        'ingredientes': [
          {
            'nombre': 'Salmón fresco',
            'gramos': 120,
            'calorias': 240,
            'proteinas': 25.0,
            'carbos': 0.0,
            'grasas': 15.0,
            'emoji': '🐟',
          },
        ],
      };

      final model = PlatoDetectadoModel.fromJson(json);
      expect(model.nombrePlato, 'Bowl de Salmón');
      expect(model.healthScore, 95);
      expect(
        model.explicacionHealthScore,
        'Excelente aporte de omega-3 y proteínas magras.',
      );
      expect(model.ingredientes.length, 1);
      expect(model.ingredientes.first.nombre, 'Salmón fresco');
      expect(model.ingredientes.first.gramos, 120.0);

      final entity = model.toEntity(id: 'plato_test_1');
      expect(entity.id, 'plato_test_1');
      expect(
        entity.explicacionHealthScore,
        'Excelente aporte de omega-3 y proteínas magras.',
      );
      expect(entity.ingredientes.first.calorias, 240);
    });
  });

  group('ScannerViewModel con Captura Real de Imagen & Matching IA', () {
    late ScannerRepositoryImpl repository;
    late ScannerViewModel vm;
    late List<IngredienteAlacena> alacenaMock;
    late ImagenPlato fakeImagen;

    setUp(() {
      repository = ScannerRepositoryImpl(
        remoteDataSource: FakeScannerRemoteDataSource(),
      );
      fakeImagen = ImagenPlato.crear(
        bytes: Uint8List.fromList([10, 20, 30, 40]),
        mimeType: 'image/jpeg',
      );
      final fakeService = FakeImageCaptureService(resultado: fakeImagen);

      vm = ScannerViewModel(
        repository: repository,
        imageCaptureService: fakeService,
      );

      final ahora = DateTime.now();
      alacenaMock = [
        IngredienteAlacena(
          id: 'ing_huevo',
          nombre: 'Huevos de campo',
          categoria: CategoriaAlacena.proteinas,
          gramosPorcion: 100.0,
          calorias: 143,
          proteinas: 13.0,
          carbohidratos: 1.0,
          grasas: 10.0,
          creadoEn: ahora,
        ),
        IngredienteAlacena(
          id: 'ing_pan_1',
          nombre: 'Pan integral',
          marca: 'Fargo',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50.0,
          calorias: 120,
          proteinas: 4.5,
          carbohidratos: 22.0,
          grasas: 1.5,
          creadoEn: ahora,
        ),
        IngredienteAlacena(
          id: 'ing_pan_2',
          nombre: 'Pan integral doble salvado',
          marca: 'Lactal',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50.0,
          calorias: 110,
          proteinas: 5.0,
          carbohidratos: 20.0,
          grasas: 1.2,
          creadoEn: ahora,
        ),
      ];
    });

    test('capturarFotoConCamara almacena la imagen en el ViewModel', () async {
      expect(vm.fotoCapturada, isNull);
      final img = await vm.capturarFotoConCamara();

      expect(img, isNotNull);
      expect(vm.fotoCapturada, isNotNull);
      expect(vm.fotoCapturada!.tamanoBytes, 4);

      vm.descartarFotoCapturada();
      expect(vm.fotoCapturada, isNull);
    });

    test(
      'seleccionarFotoDeGaleria almacena la imagen en el ViewModel',
      () async {
        final img = await vm.seleccionarFotoDeGaleria();
        expect(img, isNotNull);
        expect(vm.fotoCapturada, isNotNull);
      },
    );

    test(
      'escanear con imagen real procesa el plato y vincula con alacena',
      () async {
        await vm.capturarFotoConCamara();
        final plato = await vm.escanear(alacenaMock);

        expect(plato, isNotNull);
        expect(vm.hayPlatoDetectado, isTrue);
        expect(plato!.ingredientes, isNotEmpty);
      },
    );

    test('escanear cuando falla la IA retorna null y registra error', () async {
      final failingRepo = ScannerRepositoryImpl(
        remoteDataSource: FakeScannerRemoteDataSource(fallar: true),
      );
      final failingVm = ScannerViewModel(
        repository: failingRepo,
        imageCaptureService: FakeImageCaptureService(resultado: fakeImagen),
      );

      await failingVm.capturarFotoConCamara();
      final plato = await failingVm.escanear(alacenaMock);

      expect(plato, isNull);
      expect(failingVm.hayPlatoDetectado, isFalse);
      expect(failingVm.error, isNotNull);
    });

    test('Estado inicial es correcto', () {
      expect(vm.preferirAlacena, isTrue);
      expect(vm.escaneando, isFalse);
      expect(vm.platoDetectado, isNull);
    });

    test('toggle y setter de preferirAlacena actualizan y notifican', () {
      vm.setPreferirAlacena(false);
      expect(vm.preferirAlacena, isFalse);

      vm.togglePreferirAlacena();
      expect(vm.preferirAlacena, isTrue);
    });

    test(
      'escanear con preferirAlacena vincula con alacena y detecta conflicto multimarca',
      () async {
        final plato = await vm.escanear(alacenaMock);

        expect(plato, isNotNull);
        expect(vm.escaneando, isFalse);
        expect(plato!.ingredientes, isNotEmpty);

        // Al tener Pan Fargo y Pan Lactal en alacena, debe registrar conflicto
        expect(plato.tieneConflictosMarcas, isTrue);
        expect(plato.conflictosMarcas.first.opcionesAlacena.length, 2);
      },
    );

    test('resolverConflictoMarca reemplaza por la marca elegida', () async {
      await vm.escanear(alacenaMock);
      expect(vm.platoDetectado!.tieneConflictosMarcas, isTrue);

      final conflicto = vm.platoDetectado!.conflictosMarcas.first;
      final marcaElegida = conflicto.opcionesAlacena.last; // Pan Lactal

      vm.resolverConflictoMarca(
        nombreGenerico: conflicto.nombreGenerico,
        alacenaElegida: marcaElegida,
      );

      expect(
        vm.platoDetectado!.conflictosMarcas.any(
          (c) => c.nombreGenerico == conflicto.nombreGenerico,
        ),
        isFalse,
      );
      final modificado = vm.platoDetectado!.ingredientes.firstWhere(
        (i) => i.nombre.contains('Pan'),
      );
      expect(modificado.marca, 'Lactal');
    });

    test('ajustarGramos y fijarGramos recalculan totales del plato', () async {
      await vm.escanear(alacenaMock);
      final primerIng = vm.platoDetectado!.ingredientes.first;
      final caloriasAntes = vm.platoDetectado!.totalCalorias;

      vm.ajustarGramosIngrediente(primerIng.id, 20.0);
      expect(vm.platoDetectado!.totalCalorias, greaterThan(caloriasAntes));

      vm.fijarGramosIngrediente(primerIng.id, 50.0);
      final ingModificado = vm.platoDetectado!.ingredientes.firstWhere(
        (i) => i.id == primerIng.id,
      );
      expect(ingModificado.gramos, 50.0);
    });

    test('eliminarIngrediente y agregarIngredienteDesdeAlacena', () async {
      await vm.escanear(alacenaMock);
      final totalInicial = vm.platoDetectado!.ingredientes.length;
      final idAEliminar = vm.platoDetectado!.ingredientes.first.id;

      vm.eliminarIngrediente(idAEliminar);
      expect(vm.platoDetectado!.ingredientes.length, totalInicial - 1);
      expect(
        vm.platoDetectado!.ingredientes.any((i) => i.id == idAEliminar),
        isFalse,
      );

      // Agregar ingrediente nuevo desde la alacena
      vm.agregarIngredienteDesdeAlacena(alacenaMock.first, 80.0);
      expect(vm.platoDetectado!.ingredientes.length, totalInicial);
      expect(vm.platoDetectado!.ingredientes.last.nombre, 'Huevos de campo');
      expect(vm.platoDetectado!.ingredientes.last.gramos, 80.0);
    });

    test('reiniciar limpia el plato y resetea estado', () async {
      await vm.escanear(alacenaMock);
      expect(vm.hayPlatoDetectado, isTrue);

      vm.reiniciar();
      expect(vm.hayPlatoDetectado, isFalse);
      expect(vm.platoDetectado, isNull);
      expect(vm.fotoCapturada, isNull);
      expect(vm.error, isNull);
    });
  });
}
