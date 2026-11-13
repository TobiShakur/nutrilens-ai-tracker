import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nutrilens_provider/features/alacena/domain/datasources/barcode_demo_datasource.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_demo_chip.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_product_data.dart';
import 'package:nutrilens_provider/features/alacena/domain/failures/barcode_scan_failure.dart';
import 'package:nutrilens_provider/features/alacena/domain/services/barcode_product_service.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/barcode_scanner_state.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/barcode_scanner_viewmodel.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/image_capture_service.dart';

class FakeBarcodeDemoDatasource implements BarcodeDemoDatasource {
  final List<BarcodeDemoChip> chips;
  FakeBarcodeDemoDatasource({
    this.chips = const [
      BarcodeDemoChip(label: 'Nutella', codigo: '3017620422003'),
      BarcodeDemoChip(label: 'Yogur', codigo: '7791293022611'),
    ],
  });

  @override
  List<BarcodeDemoChip> obtenerChipsDemostracion() => chips;
}

class FakeBarcodeProductService implements BarcodeProductService {
  int llamadasBuscar = 0;
  int llamadasFoto = 0;
  String? ultimoCodigoRecibido;
  Future<BarcodeProductData?> Function(String codigo)? onBuscar;
  Future<BarcodeProductData?> Function(Uint8List bytes, String mimeType)?
  onAnalizarFoto;

  @override
  Future<BarcodeProductData?> buscarPorCodigoBarras(String codigo) {
    llamadasBuscar++;
    ultimoCodigoRecibido = codigo;
    if (onBuscar != null) return onBuscar!(codigo);
    return Future.value(null);
  }

  @override
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
  }) {
    llamadasFoto++;
    if (onAnalizarFoto != null) return onAnalizarFoto!(bytes, mimeType);
    return Future.value(null);
  }
}

class FakeImageCaptureService implements ImageCaptureService {
  int llamadasCamara = 0;
  int llamadasGaleria = 0;
  Future<ImagenPlato?> Function()? onCamara;
  Future<ImagenPlato?> Function()? onGaleria;

  @override
  Future<ImagenPlato?> capturarConCamara() {
    llamadasCamara++;
    if (onCamara != null) return onCamara!();
    return Future.value(null);
  }

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() {
    llamadasGaleria++;
    if (onGaleria != null) return onGaleria!();
    return Future.value(null);
  }
}

void main() {
  const productoSample = BarcodeProductData(
    nombre: 'Nutella',
    marca: 'Ferrero',
    porcionGramos: 15,
    calorias: 81,
    proteinas: 0.9,
    carbohidratos: 8.6,
    grasas: 4.6,
    codigoBarras: '3017620422003',
    fuente: 'Open Food Facts',
  );

  late FakeBarcodeProductService fakeBarcodeService;
  late FakeImageCaptureService fakeCaptureService;
  late FakeBarcodeDemoDatasource fakeDemoDatasource;
  late BarcodeScannerViewModel vm;

  setUp(() {
    fakeBarcodeService = FakeBarcodeProductService();
    fakeCaptureService = FakeImageCaptureService();
    fakeDemoDatasource = FakeBarcodeDemoDatasource();
    vm = BarcodeScannerViewModel(
      barcodeService: fakeBarcodeService,
      imageCaptureService: fakeCaptureService,
      demoDatasource: fakeDemoDatasource,
    );
  });

  tearDown(() {
    vm.dispose();
  });

  group('BarcodeScannerViewModel - Estado Inicial y Cambio de Modo', () {
    test('arranca en camara, BarcodeScannerIdle y chipsDemo inmutables', () {
      expect(vm.modo, equals(ModoEscaneoProducto.camara));
      expect(vm.state, equals(const BarcodeScannerIdle()));
      expect(vm.estaCargando, isFalse);
      expect(vm.chipsDemo, equals(fakeDemoDatasource.chips));
      expect(
        () => vm.chipsDemo.add(
          const BarcodeDemoChip(label: 'X', codigo: '3017620422003'),
        ),
        throwsUnsupportedError,
      );
    });

    test(
      'cambiarModo notifica 1 vez al cambiar, 0 veces si no cambia y limpia errores',
      () async {
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        vm.cambiarModo(ModoEscaneoProducto.camara);
        expect(notificaciones, equals(0));

        vm.cambiarModo(ModoEscaneoProducto.codigo);
        expect(vm.modo, equals(ModoEscaneoProducto.codigo));
        expect(notificaciones, equals(1));

        // Provocamos un error y verificamos limpieza al cambiar de modo
        await vm.buscarPorCodigoBarras('123');
        expect(vm.state, isA<BarcodeScannerError>());
        notificaciones = 0;

        vm.cambiarModo(ModoEscaneoProducto.camara);
        expect(vm.modo, equals(ModoEscaneoProducto.camara));
        expect(vm.state, equals(const BarcodeScannerIdle()));
        expect(notificaciones, equals(1));
      },
    );

    test('cambiarModo no muta ni notifica mientras está cargando', () async {
      final completer = Completer<BarcodeProductData?>();
      fakeBarcodeService.onBuscar = (_) => completer.future;

      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      vm.cambiarModo(ModoEscaneoProducto.codigo);
      final future = vm.buscarPorCodigoBarras('3017620422003');
      expect(vm.estaCargando, isTrue);
      final notifAntes = notificaciones;

      vm.cambiarModo(ModoEscaneoProducto.camara);
      expect(vm.modo, equals(ModoEscaneoProducto.codigo));
      expect(notificaciones, equals(notifAntes));

      completer.complete(productoSample);
      await future;
    });
  });

  group('BarcodeScannerViewModel - Captura de Cámara / Galería', () {
    test(
      'éxito con cámara emite Loading -> Loading -> Success y 3 notificaciones',
      () async {
        final imagen = ImagenPlato.crear(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          mimeType: 'image/jpeg',
        );
        fakeCaptureService.onCamara = () async => imagen;
        fakeBarcodeService.onAnalizarFoto = (_, _) async => productoSample;

        final estados = <BarcodeScannerState>[];
        vm.addListener(() => estados.add(vm.state));

        await vm.capturarConCamara();

        expect(estados.length, equals(3));
        expect(estados[0], isA<BarcodeScannerLoading>());
        expect(estados[1], isA<BarcodeScannerLoading>());
        expect(
          estados[2],
          equals(const BarcodeScannerSuccess(producto: productoSample)),
        );
      },
    );

    test('cancelación (null) retorna a BarcodeScannerIdle sin error', () async {
      fakeCaptureService.onGaleria = () async => null;

      await vm.seleccionarDeGaleria();

      expect(vm.state, equals(const BarcodeScannerIdle()));
      expect(fakeBarcodeService.llamadasFoto, equals(0));
    });

    test(
      'permiso denegado mapea a BarcodeErrorTipo.permisoDenegado sin \$e',
      () async {
        fakeCaptureService.onCamara = () async {
          throw const BarcodePermisoDenegadoFailure(esCamara: true);
        };

        await vm.capturarConCamara();

        expect(vm.state, isA<BarcodeScannerError>());
        final error = vm.state as BarcodeScannerError;
        expect(error.tipo, equals(BarcodeErrorTipo.permisoDenegado));
        expect(error.mensaje, contains('cámara'));
      },
    );

    test(
      'imagen > 10MB es rechazada localmente sin llamar analizarFotoEtiqueta',
      () async {
        final imagenPesada = ImagenPlato.crear(
          bytes: Uint8List(10 * 1024 * 1024 + 1),
          mimeType: 'image/jpeg',
        );
        fakeCaptureService.onCamara = () async => imagenPesada;

        await vm.capturarConCamara();

        expect(fakeBarcodeService.llamadasFoto, equals(0));
        expect(vm.state, isA<BarcodeScannerError>());
        final error = vm.state as BarcodeScannerError;
        expect(error.tipo, equals(BarcodeErrorTipo.imagenInvalida));
      },
    );

    test(
      'SEC-08: doble tap concurrente ejecuta captura una sola vez',
      () async {
        final completer = Completer<ImagenPlato?>();
        fakeCaptureService.onCamara = () => completer.future;

        final f1 = vm.capturarConCamara();
        final f2 = vm.capturarConCamara();

        expect(fakeCaptureService.llamadasCamara, equals(1));
        completer.complete(null);
        await Future.wait([f1, f2]);
      },
    );
  });

  group('BarcodeScannerViewModel - Búsqueda por Código de Barras', () {
    test(
      'código válido limpia guiones, llama servicio 1 vez y termina en Success',
      () async {
        fakeBarcodeService.onBuscar = (_) async => productoSample;
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        await vm.buscarPorCodigoBarras(' 301-762-0422003 ');

        expect(fakeBarcodeService.llamadasBuscar, equals(1));
        expect(
          fakeBarcodeService.ultimoCodigoRecibido,
          equals('3017620422003'),
        );
        expect(
          vm.state,
          equals(const BarcodeScannerSuccess(producto: productoSample)),
        );
        expect(notificaciones, equals(2));
      },
    );

    test(
      'SEC-05: código vacío, no numérico o checksum inválido no invoca servicio',
      () async {
        for (final invalido in ['', 'abc', '123', '7790070507305']) {
          await vm.buscarPorCodigoBarras(invalido);
          expect(vm.state, isA<BarcodeScannerError>());
          expect(
            (vm.state as BarcodeScannerError).tipo,
            equals(BarcodeErrorTipo.codigoInvalido),
          );
        }
        expect(fakeBarcodeService.llamadasBuscar, equals(0));
      },
    );

    test(
      'producto no encontrado (null) termina en BarcodeErrorTipo.noEncontrado',
      () async {
        fakeBarcodeService.onBuscar = (_) async => null;

        await vm.buscarPorCodigoBarras('3017620422003');

        expect(vm.state, isA<BarcodeScannerError>());
        final err = vm.state as BarcodeScannerError;
        expect(err.tipo, equals(BarcodeErrorTipo.noEncontrado));
        expect(err.mensaje, contains('3017620422003'));
      },
    );

    test(
      'SEC-02: errores tipados y excepciones crudas nunca exponen URIs ni keys',
      () async {
        final casos = <(BarcodeScanFailure, BarcodeErrorTipo)>[
          (const BarcodeTimeoutFailure(), BarcodeErrorTipo.timeout),
          (const BarcodeRateLimitFailure(), BarcodeErrorTipo.rateLimit),
          (const BarcodeRedFailure(), BarcodeErrorTipo.red),
          (const BarcodeApiKeyFaltanteFailure(), BarcodeErrorTipo.sinApiKey),
          (
            const BarcodeApiNoDisponibleFailure(statusCode: 503),
            BarcodeErrorTipo.servicioNoDisponible,
          ),
          (
            const BarcodeRespuestaInvalidaFailure(),
            BarcodeErrorTipo.desconocido,
          ),
        ];

        for (final (failure, tipoEsperado) in casos) {
          fakeBarcodeService.onBuscar = (_) async => throw failure;
          await vm.buscarPorCodigoBarras('3017620422003');
          final err = vm.state as BarcodeScannerError;
          expect(err.tipo, equals(tipoEsperado));
        }

        fakeBarcodeService.onBuscar = (_) async {
          throw http.ClientException(
            'Socket fail',
            Uri.parse(
              'https://generativelanguage.googleapis.com?key=AIzaSecret',
            ),
          );
        };
        await vm.buscarPorCodigoBarras('3017620422003');
        final errGenerico = vm.state as BarcodeScannerError;
        expect(errGenerico.tipo, equals(BarcodeErrorTipo.desconocido));
        expect(errGenerico.mensaje, isNot(contains('AIzaSecret')));
        expect(errGenerico.mensaje, isNot(contains('googleapis.com')));
        expect(errGenerico.mensaje, isNot(contains('Socket fail')));
      },
    );

    test(
      'doble tap concurrente en buscarPorCodigoBarras llama servicio 1 vez',
      () async {
        final completer = Completer<BarcodeProductData?>();
        fakeBarcodeService.onBuscar = (_) => completer.future;

        final f1 = vm.buscarPorCodigoBarras('3017620422003');
        final f2 = vm.buscarPorCodigoBarras('5449000000996');

        expect(fakeBarcodeService.llamadasBuscar, equals(1));
        completer.complete(productoSample);
        await Future.wait([f1, f2]);
      },
    );
  });

  group('BarcodeScannerViewModel - Reinicio y Dispose Seguro', () {
    test(
      'reiniciarEscaneo vuelve a Idle y no notifica si ya estaba en Idle',
      () async {
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        vm.reiniciarEscaneo();
        expect(notificaciones, equals(0));

        fakeBarcodeService.onBuscar = (_) async => productoSample;
        await vm.buscarPorCodigoBarras('3017620422003');
        expect(vm.state, isA<BarcodeScannerSuccess>());

        notificaciones = 0;
        vm.reiniciarEscaneo();
        expect(vm.state, equals(const BarcodeScannerIdle()));
        expect(notificaciones, equals(1));
      },
    );

    test(
      'dispose durante operación pendiente no lanza FlutterError ni notifica',
      () async {
        final completer = Completer<BarcodeProductData?>();
        fakeBarcodeService.onBuscar = (_) => completer.future;

        final localVm = BarcodeScannerViewModel(
          barcodeService: fakeBarcodeService,
          imageCaptureService: fakeCaptureService,
          demoDatasource: fakeDemoDatasource,
        );

        var notificacionesTrasDispose = 0;
        var disposed = false;
        localVm.addListener(() {
          if (disposed) notificacionesTrasDispose++;
        });

        final future = localVm.buscarPorCodigoBarras('3017620422003');
        expect(localVm.estaCargando, isTrue);

        disposed = true;
        localVm.dispose();

        completer.complete(productoSample);
        await future;

        expect(notificacionesTrasDispose, equals(0));
      },
    );
  });
}
