import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrilens_provider/core/constants/api_constants.dart';
import 'package:nutrilens_provider/features/diario/data/models/meal_health_evaluation_model.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/scanner/data/datasources/scanner_firebase_ai_datasource.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/failures/scanner_failure.dart';

void main() {
  final sampleImage = ImagenPlato.crear(
    bytes: Uint8List.fromList([1, 2, 3, 4]),
    mimeType: 'image/jpeg',
  );

  String geminiPayload(Map<String, dynamic> dishJson) => jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': jsonEncode(dishJson)},
          ],
        },
      },
    ],
  });

  group('ScannerFirebaseAiDataSourceImpl', () {
    test(
      'throws ScannerApiKeyMissingFailure when key and endpoint are empty',
      () async {
        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) async => http.Response('', 200)),
          apiKey: '   ',
          endpointUrl: '',
        );

        await expectLater(
          ds.analizarFotoPlato(imagen: sampleImage, nombresAlacena: const []),
          throwsA(isA<ScannerApiKeyMissingFailure>()),
        );
      },
    );

    test(
      'direct Gemini sends x-goog-api-key header without ?key= in URL',
      () async {
        late http.Request captured;
        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              geminiPayload({
                'nombrePlato': 'Omelette',
                'healthScore': 90,
                'explicacionHealthScore': 'Alto en proteína.',
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
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          apiKey: 'test-api-key',
        );

        final result = await ds.analizarFotoPlato(
          imagen: sampleImage,
          nombresAlacena: const ['Huevo'],
        );

        expect(result.nombrePlato, 'Omelette');
        expect(captured.url.queryParameters.containsKey('key'), isFalse);
        expect(captured.headers['x-goog-api-key'], 'test-api-key');
      },
    );

    test(
      'throws ScannerNoFoodDetectedFailure on empty ingredientes in direct and endpoint modes',
      () async {
        final directDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async => http.Response(
              geminiPayload({
                'nombrePlato': 'Vacio',
                'healthScore': 50,
                'explicacionHealthScore': 'Nada.',
                'ingredientes': <dynamic>[],
              }),
              200,
            ),
          ),
          apiKey: 'key',
        );

        await expectLater(
          directDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerNoFoodDetectedFailure>()),
        );

        final endpointDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'nombrePlato': 'Vacio',
                'healthScore': 50,
                'explicacionHealthScore': 'Nada.',
                'ingredientes': <dynamic>[],
              }),
              200,
            ),
          ),
          endpointUrl: 'https://api.nutrilens.test/analyze',
        );

        await expectLater(
          endpointDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerNoFoodDetectedFailure>()),
        );
      },
    );

    test(
      'maps 401/403, 429, 400, and SAFETY empty candidates to typed ScannerFailures',
      () async {
        for (final status in [401, 403]) {
          final ds = ScannerFirebaseAiDataSourceImpl(
            httpClient: MockClient(
              (_) async => http.Response('unauth', status),
            ),
            apiKey: 'bad-key',
          );
          await expectLater(
            ds.analizarFotoPlato(imagen: sampleImage, nombresAlacena: const []),
            throwsA(isA<ScannerApiKeyMissingFailure>()),
          );
        }

        final rateDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) async => http.Response('rate limit', 429)),
          apiKey: 'key',
        );
        await expectLater(
          rateDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerRateLimitFailure>()),
        );

        final badReqDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) async => http.Response('bad req', 400)),
          apiKey: 'key',
        );
        await expectLater(
          badReqDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );

        final safetyDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async =>
                http.Response(jsonEncode({'candidates': <dynamic>[]}), 200),
          ),
          apiKey: 'key',
        );
        await expectLater(
          safetyDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );
      },
    );

    test(
      'retries fallback Gemini model on 500 and recovers on 200 or throws 503 failure',
      () async {
        final urls = <String>[];
        final recoverDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((request) async {
            urls.add(request.url.toString());
            if (urls.length == 1) {
              return http.Response('server error', 500);
            }
            return http.Response(
              geminiPayload({
                'nombrePlato': 'Pollo',
                'healthScore': 88,
                'explicacionHealthScore': 'Magro.',
                'ingredientes': [
                  {
                    'nombre': 'Pollo',
                    'gramos': 150,
                    'calorias': 240,
                    'proteinas': 45,
                    'carbos': 0,
                    'grasas': 5,
                    'emoji': '🍗',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          apiKey: 'key',
        );

        final recovered = await recoverDs.analizarFotoPlato(
          imagen: sampleImage,
          nombresAlacena: const [],
        );
        expect(recovered.nombrePlato, 'Pollo');
        expect(urls.length, 2);
        expect(urls[0], contains('gemini-2.5-flash'));
        expect(urls[1], contains('gemini-flash-latest'));

        final failDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) async => http.Response('down', 503)),
          apiKey: 'key',
        );
        await expectLater(
          failDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(
            isA<ScannerServiceUnavailableFailure>().having(
              (f) => f.statusCode,
              'statusCode',
              503,
            ),
          ),
        );
      },
    );

    test(
      'maps TimeoutException and http.ClientException to typed failures',
      () async {
        final timeoutDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) => throw TimeoutException('slow')),
          apiKey: 'key',
        );
        await expectLater(
          timeoutDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerTimeoutFailure>()),
        );

        final netDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) => throw http.ClientException('offline')),
          apiKey: 'key',
        );
        await expectLater(
          netDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerNetworkFailure>()),
        );
      },
    );
  });

  group('evaluarHealthScore & MealHealthEvaluationModel', () {
    const sampleInput = MealHealthEvaluationInput(
      titulo: 'Bowl proteico',
      ingredientes: [
        MealHealthIngredientInput(
          nombre: 'Pollo grillado',
          gramos: 150,
          calorias: 248,
          proteinas: 46.5,
          carbohidratos: 0,
          grasas: 5.4,
        ),
      ],
      totalCalorias: 248,
      totalProteinas: 46.5,
      totalCarbohidratos: 0,
      totalGrasas: 5.4,
    );

    test(
      'sends x-goog-api-key header, single JSON-encoded payload, and responseSchema',
      () async {
        late http.Request capturedRequest;
        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((req) async {
            capturedRequest = req;
            return http.Response(
              geminiPayload({
                'healthScore': 88,
                'razonHealthScore':
                    'Excelente densidad proteica y muy bajas grasas saturadas.',
              }),
              200,
            );
          }),
          apiKey: 'secret-api-key',
        );

        final result = await ds.evaluarHealthScore(input: sampleInput);

        expect(result.healthScore, 88);
        expect(
          result.razonHealthScore,
          'Excelente densidad proteica y muy bajas grasas saturadas.',
        );
        expect(capturedRequest.headers['x-goog-api-key'], 'secret-api-key');
        expect(capturedRequest.url.queryParameters.containsKey('key'), isFalse);

        final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
        final generationConfig =
            body['generationConfig'] as Map<String, dynamic>;
        final schema =
            generationConfig['response_schema'] as Map<String, dynamic>;
        expect(
          schema['required'],
          containsAll(['healthScore', 'razonHealthScore']),
        );

        final userParts =
            ((body['contents'] as List).first as Map<String, dynamic>)['parts']
                as List;
        final userText =
            (userParts.first as Map<String, dynamic>)['text'] as String;
        expect(userText, contains('Bowl proteico'));
        expect(userText, contains('Pollo grillado'));
      },
    );

    test('falls back to secondary Gemini model on 404 or 5xx', () async {
      final urls = <String>[];
      final ds = ScannerFirebaseAiDataSourceImpl(
        httpClient: MockClient((req) async {
          urls.add(req.url.toString());
          if (urls.length == 1) {
            return http.Response('not found', 404);
          }
          return http.Response(
            geminiPayload({
              'healthScore': 76,
              'razonHealthScore': 'Aporte sólido de proteínas magras.',
            }),
            200,
          );
        }),
        apiKey: 'key',
      );

      final res = await ds.evaluarHealthScore(input: sampleInput);
      expect(res.healthScore, 76);
      expect(urls.length, 2);
      expect(urls.last, contains('gemini-flash-latest'));
    });

    test(
      'rejects SAFETY, RECITATION, and promptFeedback blockReason responses',
      () async {
        final safetyDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'finishReason': 'SAFETY',
                    'content': {'parts': []},
                  },
                ],
              }),
              200,
            ),
          ),
          apiKey: 'key',
        );
        await expectLater(
          safetyDs.evaluarHealthScore(input: sampleInput),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );

        final recitationDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'finishReason': 'RECITATION',
                    'content': {'parts': []},
                  },
                ],
              }),
              200,
            ),
          ),
          apiKey: 'key',
        );
        await expectLater(
          recitationDs.evaluarHealthScore(input: sampleInput),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );

        final blockedDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'promptFeedback': {'blockReason': 'SAFETY'},
                'candidates': [],
              }),
              200,
            ),
          ),
          apiKey: 'key',
        );
        await expectLater(
          blockedDs.evaluarHealthScore(input: sampleInput),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );
      },
    );

    test('rejects non-HTTPS healthScoreEndpointUrl or endpointUrl', () async {
      final ds = ScannerFirebaseAiDataSourceImpl(
        httpClient: MockClient((_) async => http.Response('', 200)),
        apiKey: '',
        healthScoreEndpointUrl: 'http://insecure.example.com/score',
      );

      await expectLater(
        ds.evaluarHealthScore(input: sampleInput),
        throwsA(isA<ScannerInvalidResponseFailure>()),
      );
    });

    test(
      'MealHealthEvaluationModel guards NaN/empty reason, clamps 0..100, and caps 280 chars',
      () {
        expect(
          () => MealHealthEvaluationModel.fromJson({
            'healthScore': double.nan,
            'razonHealthScore': 'Ok',
          }),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );
        expect(
          () => MealHealthEvaluationModel.fromJson({
            'healthScore': 80,
            'razonHealthScore': '   ',
          }),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );

        final over = MealHealthEvaluationModel.fromJson({
          'healthScore': 142.8,
          'razonHealthScore': 'X' * 320,
        });
        expect(over.healthScore, 100);
        expect(over.razonHealthScore.length, 280);

        final under = MealHealthEvaluationModel.fromJson({
          'healthScore': -15,
          'razonHealthScore': 'Bajo en micronutrientes.\n\x00Extra',
        });
        expect(under.healthScore, 0);
        expect(under.razonHealthScore.contains('\n'), isFalse);
        expect(under.razonHealthScore.contains('\x00'), isFalse);
      },
    );

    test(
      'proxyUrl routes analizarFotoPlato and evaluarHealthScore via proxy without apiKey or x-goog-api-key header',
      () async {
        final capturedRequests = <http.Request>[];
        var callCount = 0;

        final ds = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((request) async {
            capturedRequests.add(request);
            callCount++;
            if (callCount == 1) {
              // Trigger fallback to gemini-flash-latest on 503.
              return http.Response('unavailable', 503);
            }
            if (callCount == 2) {
              return http.Response(
                geminiPayload({
                  'nombrePlato': 'Ensalada',
                  'healthScore': 95,
                  'explicacionHealthScore': 'Muy nutritivo.',
                  'ingredientes': [
                    {
                      'nombre': 'Lechuga',
                      'gramos': 100,
                      'calorias': 15,
                      'proteinas': 1.4,
                      'carbos': 2.9,
                      'grasas': 0.2,
                      'emoji': '🥬',
                    },
                  ],
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response(
              geminiPayload({
                'healthScore': 91,
                'razonHealthScore': 'Balance excelente.',
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          apiKey: '',
          proxyUrl: 'https://nutrilens-gemini-proxy.test.workers.dev/',
        );

        final dish = await ds.analizarFotoPlato(
          imagen: sampleImage,
          nombresAlacena: const [],
        );
        expect(dish.nombrePlato, 'Ensalada');

        final health = await ds.evaluarHealthScore(input: sampleInput);
        expect(health.healthScore, 91);

        expect(capturedRequests.length, 3);
        expect(
          capturedRequests[0].url.toString(),
          'https://nutrilens-gemini-proxy.test.workers.dev/v1beta/models/gemini-2.5-flash:generateContent',
        );
        expect(
          capturedRequests[1].url.toString(),
          'https://nutrilens-gemini-proxy.test.workers.dev/v1beta/models/gemini-flash-latest:generateContent',
        );
        expect(
          capturedRequests[2].url.toString(),
          'https://nutrilens-gemini-proxy.test.workers.dev/v1beta/models/gemini-2.5-flash:generateContent',
        );
        for (final req in capturedRequests) {
          expect(req.headers.containsKey('x-goog-api-key'), isFalse);
        }
      },
    );

    test(
      'rejects non-HTTPS remote proxyUrl and allows localhost http',
      () async {
        final insecureDs = ScannerFirebaseAiDataSourceImpl(
          httpClient: MockClient((_) async => http.Response('', 200)),
          apiKey: '',
          proxyUrl: 'http://insecure.example.com',
        );
        await expectLater(
          insecureDs.analizarFotoPlato(
            imagen: sampleImage,
            nombresAlacena: const [],
          ),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );

        final localUris = ApiConstants.resolveGeminiProxyUris(
          'http://127.0.0.1:8787/',
        );
        expect(
          localUris?.primary.toString(),
          'http://127.0.0.1:8787/v1beta/models/gemini-2.5-flash:generateContent',
        );
      },
    );
  });
}
