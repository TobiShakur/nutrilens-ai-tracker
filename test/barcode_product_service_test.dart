import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrilens_provider/features/alacena/data/datasources/barcode_product_service_impl.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_product_data.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';

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
        // 539 * (15/100) = 80.85 -> round 81 kcal
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
        final resultado = await service.buscarPorCodigoBarras('7790070507305');

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
      'buscarPorCodigoBarras sanitiza espacios y caracteres no numéricos',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.pathSegments.last, equals('7790070507305.json'));
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
          ' 779-007-050-7305 ',
        );

        expect(resultado, isNotNull);
        expect(resultado!.codigoBarras, equals('7790070507305'));
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
      'buscarPorCodigoBarras devuelve null para string vacío o sin dígitos',
      () async {
        final mockClient = MockClient((_) async => http.Response('{}', 200));
        final service = BarcodeProductServiceImpl(httpClient: mockClient);

        final res1 = await service.buscarPorCodigoBarras('');
        final res2 = await service.buscarPorCodigoBarras('   ---   ');

        expect(res1, isNull);
        expect(res2, isNull);
      },
    );
  });
}
