import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/barcode_product_data.dart';
import '../../domain/services/barcode_product_service.dart';

/// Implementación de producción para la resolución de productos por código de barras
/// (vía Open Food Facts API v2 con fallback heurístico) y visión artificial (Gemini 2.5 Flash).
class BarcodeProductServiceImpl implements BarcodeProductService {
  final http.Client _httpClient;
  final String? apiKey;

  BarcodeProductServiceImpl({http.Client? httpClient, this.apiKey})
    : _httpClient = httpClient ?? http.Client();

  String get _geminiKey => apiKey ?? ApiConstants.geminiApiKey;

  @override
  Future<BarcodeProductData?> buscarPorCodigoBarras(String codigo) async {
    final sanitized = codigo.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) return null;

    // 1. Consulta prioritaria a Open Food Facts
    try {
      final offUrl = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$sanitized.json',
      );
      final response = await _httpClient
          .get(
            offUrl,
            headers: {
              'User-Agent':
                  'NutriLensAI/1.0 (nutrilens@fitiafake.app; flutter-web)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['status'] == 1) {
          final product = decoded['product'] as Map<String, dynamic>?;
          if (product != null) {
            return _parsearOpenFoodFacts(product, sanitized);
          }
        }
      }
    } catch (e) {
      debugPrint('[BarcodeService] Error al consultar Open Food Facts: $e');
    }

    // 2. Si Open Food Facts no lo tiene y contamos con Gemini API Key, fallback con IA
    if (_geminiKey.isNotEmpty) {
      try {
        return await _consultarGeminiPorCodigo(sanitized);
      } catch (e) {
        debugPrint('[BarcodeService] Fallback Gemini falló: $e');
      }
    }

    return null;
  }

  @override
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (bytes.isEmpty) return null;
    final key = _geminiKey;
    if (key.isEmpty) {
      throw StateError(
        'Se requiere GEMINI_API_KEY para analizar fotos de etiquetas.',
      );
    }

    final base64Image = base64Encode(bytes);
    final primaryUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key',
    );
    final fallbackUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$key',
    );

    const prompt = '''
Sos un sistema de visión artificial y nutrición de máxima precisión.
Analizá la imagen provista. Puede ser una fotografía de un código de barras de producto alimenticio, el frente del envase/paquete o una tabla de información nutricional.

TAREAS:
1. Leé los dígitos numéricos del código de barras si están visibles o impresos en el empaque.
2. Identificá el nombre exacto del producto y su marca comercial principal.
3. Extraé la porción recomendada en gramos o mililitros (ej: 30, 40, 100). Si la tabla solo detalla valores cada 100g, usá 100.
4. Extraé o calculá las calorías (Kcal), proteínas (g), carbohidratos (g) y grasas (g) correspondientes a esa porción.
5. Sugerí la categoría más pertinente ('proteinas', 'carbohidratos', 'lacteos', 'grasas', 'vegetales', 'otros').
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'response_schema': {
          'type': 'OBJECT',
          'properties': {
            'nombre': {'type': 'STRING'},
            'marca': {'type': 'STRING'},
            'porcionGramos': {'type': 'NUMBER'},
            'calorias': {'type': 'INTEGER'},
            'proteinas': {'type': 'NUMBER'},
            'carbos': {'type': 'NUMBER'},
            'grasas': {'type': 'NUMBER'},
            'categoriaSugerida': {'type': 'STRING'},
            'codigoBarras': {'type': 'STRING'},
          },
          'required': [
            'nombre',
            'porcionGramos',
            'calorias',
            'proteinas',
            'carbos',
            'grasas',
          ],
        },
      },
    });

    http.Response response;
    try {
      response = await _httpClient
          .post(
            primaryUrl,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode != 200) {
        response = await _httpClient
            .post(
              fallbackUrl,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 18));
      }
    } catch (_) {
      response = await _httpClient
          .post(
            fallbackUrl,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 18));
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Fallo en API de Gemini Vision (status ${response.statusCode})',
      );
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = jsonMap['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates[0]['content'];
    final parts = content['parts'] as List;
    final text = parts[0]['text'] as String;

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    final nombre = (parsed['nombre'] as String?)?.trim();
    if (nombre == null || nombre.isEmpty) return null;

    final porcion = _toDouble(parsed['porcionGramos'], fallback: 100.0);
    final calorias = _toInt(parsed['calorias'], fallback: 0);
    final proteinas = _toDouble(parsed['proteinas'], fallback: 0.0);
    final carbos = _toDouble(parsed['carbos'], fallback: 0.0);
    final grasas = _toDouble(parsed['grasas'], fallback: 0.0);
    final marca = (parsed['marca'] as String?)?.trim() ?? '';
    final categoria = parsed['categoriaSugerida'] as String?;
    final barcode = (parsed['codigoBarras'] as String?)?.trim();

    return BarcodeProductData(
      nombre: nombre,
      marca: marca,
      porcionGramos: porcion > 0 ? porcion : 100.0,
      calorias: calorias >= 0 ? calorias : 0,
      proteinas: proteinas >= 0 ? proteinas : 0.0,
      carbohidratos: carbos >= 0 ? carbos : 0.0,
      grasas: grasas >= 0 ? grasas : 0.0,
      categoriaIdSugerida: categoria,
      codigoBarras: barcode?.isNotEmpty == true ? barcode : null,
      fuente: 'Gemini Vision AI',
    );
  }

  BarcodeProductData _parsearOpenFoodFacts(
    Map<String, dynamic> product,
    String codigo,
  ) {
    final nombre =
        (product['product_name_es'] as String?)?.trim().isNotEmpty == true
        ? product['product_name_es'] as String
        : (product['product_name'] as String?)?.trim().isNotEmpty == true
        ? product['product_name'] as String
        : 'Producto $codigo';

    final marca = (product['brands'] as String?)?.split(',').first.trim() ?? '';

    // Extracción de tamaño de porción
    double porcion = 100.0;
    if (product['serving_quantity'] != null) {
      porcion = _toDouble(product['serving_quantity'], fallback: 100.0);
    } else if (product['serving_size'] is String) {
      final match = RegExp(
        r'(\d+[\.,]?\d*)',
      ).firstMatch(product['serving_size'] as String);
      if (match != null) {
        porcion = _toDouble(match.group(1), fallback: 100.0);
      }
    }
    if (porcion <= 0) porcion = 100.0;

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Si tenemos datos específicos por porción, los usamos; si no, por 100g y escalamos
    final tienePorcion = nutriments['energy-kcal_serving'] != null;

    double cal;
    double prot;
    double carb;
    double gras;

    if (tienePorcion) {
      cal = _toDouble(nutriments['energy-kcal_serving']);
      prot = _toDouble(nutriments['proteins_serving']);
      carb = _toDouble(nutriments['carbohydrates_serving']);
      gras = _toDouble(nutriments['fat_serving']);
    } else {
      final factor = porcion / 100.0;
      cal = _toDouble(nutriments['energy-kcal_100g']) * factor;
      prot = _toDouble(nutriments['proteins_100g']) * factor;
      carb = _toDouble(nutriments['carbohydrates_100g']) * factor;
      gras = _toDouble(nutriments['fat_100g']) * factor;
    }

    // Fallback de energía si viene en kJ
    if (cal <= 0 && nutriments['energy_100g'] != null) {
      cal = (_toDouble(nutriments['energy_100g']) / 4.184) * (porcion / 100.0);
    }

    return BarcodeProductData(
      nombre: nombre,
      marca: marca,
      porcionGramos: porcion,
      calorias: cal.round(),
      proteinas: double.parse(prot.toStringAsFixed(1)),
      carbohidratos: double.parse(carb.toStringAsFixed(1)),
      grasas: double.parse(gras.toStringAsFixed(1)),
      codigoBarras: codigo,
      fuente: 'Open Food Facts',
    );
  }

  Future<BarcodeProductData?> _consultarGeminiPorCodigo(String codigo) async {
    final key = _geminiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key',
    );

    final prompt =
        '''
El usuario introdujo el código de barras numérico: "$codigo".
Si conocés el alimento o producto de consumo masivo asociado a este código EAN/UPC (con foco en Argentina y Latinoamérica), identificá su nombre comercial, marca, porción estándar (en gramos) y macros por porción.
Si no lo conocés con absoluta certeza, respondé con null o un objeto vacío.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'response_schema': {
          'type': 'OBJECT',
          'properties': {
            'nombre': {'type': 'STRING'},
            'marca': {'type': 'STRING'},
            'porcionGramos': {'type': 'NUMBER'},
            'calorias': {'type': 'INTEGER'},
            'proteinas': {'type': 'NUMBER'},
            'carbos': {'type': 'NUMBER'},
            'grasas': {'type': 'NUMBER'},
            'categoriaSugerida': {'type': 'STRING'},
          },
          'required': [
            'nombre',
            'porcionGramos',
            'calorias',
            'proteinas',
            'carbos',
            'grasas',
          ],
        },
      },
    });

    final res = await _httpClient
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = jsonMap['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]['content']['parts'][0]['text'] as String;
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        final nombre = parsed['nombre'] as String?;
        if (nombre != null && nombre.trim().isNotEmpty) {
          return BarcodeProductData(
            nombre: nombre.trim(),
            marca: (parsed['marca'] as String?)?.trim() ?? '',
            porcionGramos: _toDouble(parsed['porcionGramos'], fallback: 100.0),
            calorias: _toInt(parsed['calorias'], fallback: 0),
            proteinas: _toDouble(parsed['proteinas'], fallback: 0.0),
            carbohidratos: _toDouble(parsed['carbos'], fallback: 0.0),
            grasas: _toDouble(parsed['grasas'], fallback: 0.0),
            categoriaIdSugerida: parsed['categoriaSugerida'] as String?,
            codigoBarras: codigo,
            fuente: 'Gemini AI Assistant',
          );
        }
      }
    }
    return null;
  }

  static double _toDouble(dynamic val, {double fallback = 0.0}) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  static int _toInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? fallback;
    }
    return fallback;
  }
}
