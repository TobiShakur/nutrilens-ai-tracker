import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrilens_provider/core/network/log_sanitizer.dart';
import 'package:nutrilens_provider/features/alacena/data/datasources/barcode_product_service_impl.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_product_data.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_validator.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/failures/barcode_scan_failure.dart';
import 'package:nutrilens_provider/features/scanner/data/datasources/scanner_firebase_ai_datasource.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';

void main() {
  group('BarcodeProductData Value Object & Heurísticas de Categoría', () {
    final categorias = [
      CategoriaAlacena.proteinas,
      CategoriaAlacena.carbohidratos,
      CategoriaAlacena.grasas,
      CategoriaAlacena.lacteos,
      CategoriaAlacena.vegetales,
      CategoriaAlacena.otros,
    ];

    test(
      'Infiere categoría Proteínas si el ratio proteico es predominante',
      () {
        const data = BarcodeProductData(
          nombre: 'Pechuga de Pavo',
          marca: 'Granja',
          porcionGramos: 100,
          calorias: 110,
          proteinas: 24.0,
          carbohidratos: 0.0,
          grasas: 1.5,
          fuente: 'Open Food Facts',
        );

        final cat = data.resolverCategoriaSugerida(categorias);
        expect(cat.id, equals('proteinas'));
      },
    );

    test('Infiere categoría Grasas si el ratio lipídico es predominante', () {
      const data = BarcodeProductData(
        nombre: 'Aceite de Oliva Extra Virgen',
        marca: 'Zuelo',
        porcionGramos: 15,
        calorias: 125,
        proteinas: 0.0,
        carbohidratos: 0.0,
        grasas: 14.0,
        fuente: 'Open Food Facts',
      );

      final cat = data.resolverCategoriaSugerida(categorias);
      expect(cat.id, equals('grasas'));
    });

    test('Infiere categoría Carbohidratos si predominan los glúcidos', () {
      const data = BarcodeProductData(
        nombre: 'Avena Instantánea',
        marca: 'Quaker',
        porcionGramos: 40,
        calorias: 150,
        proteinas: 4.8,
        carbohidratos: 26.0,
        grasas: 2.8,
        fuente: 'Open Food Facts',
      );

      final cat = data.resolverCategoriaSugerida(categorias);
      expect(cat.id, equals('carbohidratos'));
    });

    test(
      'Respeta categoriaIdSugerida explícita cuando coincide con la lista',
      () {
        const data = BarcodeProductData(
          nombre: 'Queso Port Salut',
          marca: 'La Serenísima',
          porcionGramos: 30,
          calorias: 88,
          proteinas: 6.9,
          carbohidratos: 0.6,
          grasas: 6.5,
          categoriaIdSugerida: 'lacteos',
          fuente: 'Gemini Vision AI',
        );

        final cat = data.resolverCategoriaSugerida(categorias);
        expect(cat.id, equals('lacteos'));
      },
    );

    test('normalizar aplica cotas finitas, truncado y valida código GS1', () {
      final largoNombre = 'A' * 150;
      final largoMarca = 'B' * 100;

      final data = BarcodeProductData.normalizar(
        nombre: '  $largoNombre  ',
        marca: '  $largoMarca  ',
        porcionGramos: double.nan,
        calorias: -50,
        proteinas: double.infinity,
        carbohidratos: -12.4,
        grasas: 1500.0,
        codigoBarras: '7790070507305', // checksum GS1 inválido
        fuente: 'Gemini Vision AI',
      );

      expect(data.nombre.length, equals(BarcodeProductData.maxNombreChars));
      expect(data.marca.length, equals(BarcodeProductData.maxMarcaChars));
      expect(data.porcionGramos, equals(100.0));
      expect(data.calorias, equals(0));
      expect(data.proteinas, equals(0.0));
      expect(data.carbohidratos, equals(0.0));
      expect(data.grasas, equals(1000.0));
      expect(data.codigoBarras, isNull);
    });
  });

  group('BarcodeValidator (GS1 & Payloads de Etiqueta)', () {
    test('acepta códigos GS1 válidos EAN-8, UPC-A, EAN-13 y GTIN-14', () {
      expect(BarcodeValidator.esCodigoValido('96385074'), isTrue); // EAN-8
      expect(BarcodeValidator.esCodigoValido('036000291452'), isTrue); // UPC-A
      expect(
        BarcodeValidator.esCodigoValido('3017620422003'),
        isTrue,
      ); // EAN-13
      expect(
        BarcodeValidator.esCodigoValido('5449000000996'),
        isTrue,
      ); // EAN-13
      expect(
        BarcodeValidator.esCodigoValido('7791293022611'),
        isTrue,
      ); // EAN-13
      expect(
        BarcodeValidator.esCodigoValido('10012345678902'),
        isTrue,
      ); // GTIN-14
    });

    test('rechaza longitudes inválidas y checksum mod-10 erróneo', () {
      expect(BarcodeValidator.esCodigoValido(''), isFalse);
      expect(BarcodeValidator.esCodigoValido('123'), isFalse);
      expect(BarcodeValidator.esCodigoValido('123456789'), isFalse);
      expect(BarcodeValidator.esCodigoValido('7790070507305'), isFalse);
      expect(BarcodeValidator.esCodigoValido('3017620422004'), isFalse);
    });

    test(
      'validarImagenEtiqueta exige bytes no vacíos, <=10MB y MIME válido',
      () {
        expect(
          BarcodeValidator.validarImagenEtiqueta(Uint8List(0), 'image/jpeg'),
          equals('vacia'),
        );
        expect(
          BarcodeValidator.validarImagenEtiqueta(
            Uint8List(BarcodeValidator.maxBytesEtiqueta + 1),
            'image/jpeg',
          ),
          equals('tamano_excedido'),
        );
        expect(
          BarcodeValidator.validarImagenEtiqueta(
            Uint8List.fromList([1, 2, 3]),
            'application/pdf',
          ),
          equals('mime_no_soportado'),
        );
        expect(
          BarcodeValidator.validarImagenEtiqueta(
            Uint8List.fromList([1, 2, 3]),
            'image/svg+xml',
          ),
          equals('mime_no_soportado'),
        );
        expect(
          BarcodeValidator.validarImagenEtiqueta(
            Uint8List.fromList([1, 2, 3]),
            'IMAGE/WEBP',
          ),
          isNull,
        );
      },
    );
  });

  group('LogSanitizer', () {
    test(
      'redacta query params sensibles, API keys y trunca body a 200 chars',
      () {
        final msg = LogSanitizer.sanitizarMensaje(
          'Error en https://api.test/v1?key=AIzaSySecret123456&token=abc123',
        );
        expect(msg, isNot(contains('AIzaSySecret123456')));
        expect(msg, isNot(contains('abc123')));
        expect(msg, contains('[REDACTED]'));

        final truncado = LogSanitizer.truncarBody('x' * 250);
        expect(truncado.length, equals(203));
        expect(truncado.endsWith('...'), isTrue);
      },
    );
  });

  group('BarcodeProductServiceImpl & Open Food Facts API', () {
    test(
      'buscarPorCodigoBarras parsea correctamente un producto con datos por 100g',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.toString().contains('3017620422003')) {
            final json = {
              'status': 1,
              'product': {
                'product_name': 'Nutella',
                'brands': 'Ferrero, Nutella',
                'serving_quantity': 15,
                'nutriments': {
                  'energy-kcal_100g': 539,
                  'proteins_100g': 6.3,
                  'carbohydrates_100g': 57.5,
                  'fat_100g': 30.9,
                },
              },
            };
            return http.Response(jsonEncode(json), 200);
          }
          return http.Response('{"status": 0}', 404);
        });

        final service = BarcodeProductServiceImpl(httpClient: mockClient);
        final resultado = await service.buscarPorCodigoBarras('3017620422003');

        expect(resultado, isNotNull);
        expect(resultado!.nombre, equals('Nutella'));
        expect(resultado.marca, equals('Ferrero'));
        expect(resultado.porcionGramos, equals(15.0));
        expect(resultado.calorias, equals(81));
        expect(resultado.fuente, equals('Open Food Facts'));
      },
    );

    test(
      'buscarPorCodigoBarras usa datos por porción si están disponibles',
      () async {
        final mockClient = MockClient((request) async {
          final json = {
            'status': 1,
            'product': {
              'product_name_es': 'Yogur Natural Entero',
              'brands': 'La Serenísima',
              'serving_size': '190g',
              'nutriments': {
                'energy-kcal_serving': 120,
                'proteins_serving': 6.8,
                'carbohydrates_serving': 11.2,
                'fat_serving': 5.4,
              },
            },
          };
          return http.Response(jsonEncode(json), 200);
        });

        final service = BarcodeProductServiceImpl(httpClient: mockClient);
        final resultado = await service.buscarPorCodigoBarras('7791293022611');

        expect(resultado, isNotNull);
        expect(resultado!.nombre, equals('Yogur Natural Entero'));
        expect(resultado.marca, equals('La Serenísima'));
        expect(resultado.porcionGramos, equals(190.0));
        expect(resultado.calorias, equals(120));
        expect(resultado.proteinas, equals(6.8));
        expect(resultado.carbohidratos, equals(11.2));
        expect(resultado.grasas, equals(5.4));
      },
    );

    test(
      'buscarPorCodigoBarras sanitiza espacios y guiones en códigos GS1 válidos',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.pathSegments.last, equals('7791293022611.json'));
          final json = {
            'status': 1,
            'product': {
              'product_name': 'Producto Prueba',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 10,
                'carbohydrates_100g': 10,
                'fat_100g': 2,
              },
            },
          };
          return http.Response(jsonEncode(json), 200);
        });

        final service = BarcodeProductServiceImpl(httpClient: mockClient);
        final resultado = await service.buscarPorCodigoBarras(
          ' 779-129-302-2611 ',
        );

        expect(resultado, isNotNull);
        expect(resultado!.codigoBarras, equals('7791293022611'));
      },
    );

    test(
      'buscarPorCodigoBarras normaliza NaN, Infinity, negativos y porción < 1g',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Producto Extremo',
                'serving_quantity': 0.2,
                'nutriments': {
                  'energy-kcal_serving': -50,
                  'proteins_serving': 'NaN',
                  'carbohydrates_serving': 'Infinity',
                  'fat_serving': 2500,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service = BarcodeProductServiceImpl(httpClient: mockClient);
        final resultado = await service.buscarPorCodigoBarras('3017620422003');

        expect(resultado, isNotNull);
        expect(resultado!.porcionGramos, equals(1.0));
        expect(resultado.calorias, equals(0));
        expect(resultado.proteinas, equals(0.0));
        expect(resultado.carbohidratos, equals(0.0));
        expect(resultado.grasas, equals(1000.0));
      },
    );

    test(
      'buscarPorCodigoBarras devuelve null si el producto no existe y no hay IA',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"status": 0, "status_verbose": "product not found"}',
            200,
          );
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: '',
        );
        final resultado = await service.buscarPorCodigoBarras('0000000000000');

        expect(resultado, isNull);
      },
    );

    test(
      'buscarPorCodigoBarras rechaza localmente código vacío o inválido sin hacer HTTP',
      () async {
        var requests = 0;
        final mockClient = MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        });
        final service = BarcodeProductServiceImpl(httpClient: mockClient);

        await expectLater(
          service.buscarPorCodigoBarras(''),
          throwsA(isA<BarcodeCodigoInvalidoFailure>()),
        );
        await expectLater(
          service.buscarPorCodigoBarras('   ---   '),
          throwsA(isA<BarcodeCodigoInvalidoFailure>()),
        );
        await expectLater(
          service.buscarPorCodigoBarras('7790070507305'),
          throwsA(isA<BarcodeCodigoInvalidoFailure>()),
        );
        expect(requests, equals(0));
      },
    );

    test(
      'fallback Gemini por código usa header x-goog-api-key y no ?key= en URI',
      () async {
        late http.Request capturedGeminiReq;
        final mockClient = MockClient((request) async {
          if (request.url.host == 'world.openfoodfacts.org') {
            return http.Response('{"status": 0}', 200);
          }
          capturedGeminiReq = request;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'nombre': 'Barrita Proteica',
                          'marca': 'Nutri',
                          'porcionGramos': 45,
                          'calorias': 180,
                          'proteinas': 15.0,
                          'carbos': 18.0,
                          'grasas': 5.0,
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: 'secret-test-key',
        );
        final res = await service.buscarPorCodigoBarras('0000000000000');

        expect(res, isNotNull);
        expect(res!.fuente, equals('Gemini AI Assistant'));
        expect(
          capturedGeminiReq.url.queryParameters.containsKey('key'),
          isFalse,
        );
        expect(
          capturedGeminiReq.headers['x-goog-api-key'],
          equals('secret-test-key'),
        );
      },
    );
  });

  group('BarcodeProductServiceImpl & analizarFotoEtiqueta (SecOps)', () {
    test(
      'SEC-01: envía API key en header x-goog-api-key y nunca en query ?key=',
      () async {
        late http.Request capturedReq;
        final mockClient = MockClient((request) async {
          capturedReq = request;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'nombre': 'Yogur Griego',
                          'marca': 'Tregar',
                          'porcionGramos': 150,
                          'calorias': 120,
                          'proteinas': 12.5,
                          'carbos': 8.0,
                          'grasas': 3.2,
                          'codigoBarras': '7791293022611',
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: 'gemini-key-123',
        );

        final res = await service.analizarFotoEtiqueta(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          mimeType: 'image/jpeg',
        );

        expect(res, isNotNull);
        expect(res!.nombre, equals('Yogur Griego'));
        expect(res.codigoBarras, equals('7791293022611'));
        expect(capturedReq.url.queryParameters.containsKey('key'), isFalse);
        expect(capturedReq.headers['x-goog-api-key'], equals('gemini-key-123'));
      },
    );

    test(
      'SEC-06: rechaza bytes vacíos, >10MB y MIME fuera de allowlist antes de HTTP POST',
      () async {
        var requests = 0;
        final mockClient = MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: 'gemini-key-123',
        );

        await expectLater(
          service.analizarFotoEtiqueta(
            bytes: Uint8List(0),
            mimeType: 'image/jpeg',
          ),
          throwsA(
            isA<BarcodeImagenInvalidaFailure>().having(
              (f) => f.razon,
              'razon',
              'vacia',
            ),
          ),
        );

        await expectLater(
          service.analizarFotoEtiqueta(
            bytes: Uint8List(10 * 1024 * 1024 + 1),
            mimeType: 'image/jpeg',
          ),
          throwsA(
            isA<BarcodeImagenInvalidaFailure>().having(
              (f) => f.razon,
              'razon',
              'tamano_excedido',
            ),
          ),
        );

        await expectLater(
          service.analizarFotoEtiqueta(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'application/pdf',
          ),
          throwsA(
            isA<BarcodeImagenInvalidaFailure>().having(
              (f) => f.razon,
              'razon',
              'mime_no_soportado',
            ),
          ),
        );

        expect(requests, equals(0));
      },
    );

    test(
      'SEC-07: NO reintenta fallbackUrl ante 401/403/429 y SÍ reintenta ante 404/500',
      () async {
        var calls = 0;
        final unauthorizedClient = MockClient((_) async {
          calls++;
          return http.Response('{"error":"unauthorized"}', 401);
        });
        final service401 = BarcodeProductServiceImpl(
          httpClient: unauthorizedClient,
          apiKey: 'bad-key',
        );

        await expectLater(
          service401.analizarFotoEtiqueta(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/png',
          ),
          throwsA(isA<BarcodeApiKeyFaltanteFailure>()),
        );
        expect(calls, equals(1));

        var rateCalls = 0;
        final rateClient = MockClient((_) async {
          rateCalls++;
          return http.Response('{"error":"rate"}', 429);
        });
        final service429 = BarcodeProductServiceImpl(
          httpClient: rateClient,
          apiKey: 'key',
        );

        await expectLater(
          service429.analizarFotoEtiqueta(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/png',
          ),
          throwsA(isA<BarcodeRateLimitFailure>()),
        );
        expect(rateCalls, equals(1));

        final urlsHit = <String>[];
        final retryClient = MockClient((req) async {
          urlsHit.add(req.url.path);
          if (req.url.path.contains('gemini-2.5-flash')) {
            return http.Response('server error', 500);
          }
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'nombre': 'Avena',
                          'porcionGramos': 40,
                          'calorias': 140,
                          'proteinas': 5,
                          'carbos': 24,
                          'grasas': 3,
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service500 = BarcodeProductServiceImpl(
          httpClient: retryClient,
          apiKey: 'key',
        );
        final res = await service500.analizarFotoEtiqueta(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
        );

        expect(res, isNotNull);
        expect(urlsHit.length, equals(2));
        expect(urlsHit.first, contains('gemini-2.5-flash'));
        expect(urlsHit.last, contains('gemini-flash-latest'));
      },
    );

    test(
      'SEC-07: maneja respuesta 200 con finishReason SAFETY sin parts sin lanzar excepción',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {'finishReason': 'SAFETY'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: 'key',
        );

        final res = await service.analizarFotoEtiqueta(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        );

        expect(res, isNull);
      },
    );

    test(
      'SEC-04: analizarFotoEtiqueta normaliza NaN, Infinity, negativos y código inválido',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'nombre': '  Granola Fit  ',
                          'marca': '  Natural  ',
                          'porcionGramos': 0.2,
                          'calorias': -20,
                          'proteinas': 'NaN',
                          'carbos': 'Infinity',
                          'grasas': -5.4,
                          'codigoBarras': '12345',
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final service = BarcodeProductServiceImpl(
          httpClient: mockClient,
          apiKey: 'key',
        );
        final res = await service.analizarFotoEtiqueta(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        );

        expect(res, isNotNull);
        expect(res!.nombre, equals('Granola Fit'));
        expect(res.marca, equals('Natural'));
        expect(res.porcionGramos, equals(1.0));
        expect(res.calorias, equals(0));
        expect(res.proteinas, equals(0.0));
        expect(res.carbohidratos, equals(0.0));
        expect(res.grasas, equals(0.0));
        expect(res.codigoBarras, isNull);
      },
    );
  });

  group('ScannerFirebaseAiDataSourceImpl (SecOps)', () {
    final imagenTest = ImagenPlato.crear(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      mimeType: 'image/jpeg',
    );

    test(
      'SEC-03 & SEC-07: prioriza endpointUrl sobre apiKey y NO simula datos locales si falla',
      () async {
        final calledUrls = <Uri>[];
        final mockClient = MockClient((request) async {
          calledUrls.add(request.url);
          return http.Response('Internal Server Error', 500);
        });

        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: mockClient,
          endpointUrl: 'https://api.nutrilens.test/analyze',
          apiKey: 'gemini-dev-key',
        );

        await expectLater(
          ds.analizarFotoPlato(
            imagen: imagenTest,
            nombresAlacena: ['Avena\ncon\ninyección'],
          ),
          throwsException,
        );

        expect(calledUrls.length, equals(1));
        expect(
          calledUrls.first.toString(),
          equals('https://api.nutrilens.test/analyze'),
        );
      },
    );

    test(
      'SEC-01: llamado directo a Gemini usa header x-goog-api-key y no ?key= en URI',
      () async {
        late http.Request capturedReq;
        final mockClient = MockClient((request) async {
          capturedReq = request;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'nombrePlato': 'Omelette',
                          'healthScore': 90,
                          'explicacionHealthScore': 'Rico en proteínas.',
                          'ingredientes': [
                            {
                              'nombre': 'Huevo',
                              'gramos': 120,
                              'calorias': 170,
                              'proteinas': 15,
                              'carbos': 1,
                              'grasas': 12,
                              'emoji': '🥚',
                            },
                          ],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: mockClient,
          apiKey: 'gemini-direct-key',
        );

        final res = await ds.analizarFotoPlato(
          imagen: imagenTest,
          nombresAlacena: ['Huevo'],
        );

        expect(res.nombrePlato, equals('Omelette'));
        expect(capturedReq.url.queryParameters.containsKey('key'), isFalse);
        expect(
          capturedReq.headers['x-goog-api-key'],
          equals('gemini-direct-key'),
        );
      },
    );
  });
}
