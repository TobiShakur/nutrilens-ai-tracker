import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/log_sanitizer.dart';
import '../../domain/entities/barcode_product_data.dart';
import '../../domain/entities/barcode_validator.dart';
import '../../domain/failures/barcode_scan_failure.dart';
import '../../domain/services/barcode_product_service.dart';

/// Implementación de producción para la resolución de productos por código de barras
/// (Open Food Facts API v2 con fallback condicional a Gemini) y visión artificial.
class BarcodeProductServiceImpl implements BarcodeProductService {
  static final Uri _geminiPrimaryUrl = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
  );
  static final Uri _geminiFallbackUrl = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
  );

  final http.Client _httpClient;
  final String? apiKey;
  final String? proxyUrl;

  BarcodeProductServiceImpl({
    http.Client? httpClient,
    this.apiKey,
    this.proxyUrl,
  }) : _httpClient = httpClient ?? http.Client();

  String get _geminiKey => (apiKey ?? ApiConstants.geminiApiKey).trim();
  String get _geminiProxyUrl =>
      (proxyUrl ?? ApiConstants.geminiProxyUrl).trim();
  bool get _usaProxy => _geminiProxyUrl.isNotEmpty;
  bool get _tieneGeminiDisponible => _usaProxy || _geminiKey.isNotEmpty;

  @override
  Future<BarcodeProductData?> buscarPorCodigoBarras(
    String codigo, {
    String languageCode = 'es',
  }) async {
    final sanitized = BarcodeValidator.limpiar(codigo);
    if (!BarcodeValidator.esCodigoValido(sanitized)) {
      throw const BarcodeCodigoInvalidoFailure();
    }

    // 1. Consulta prioritaria a Open Food Facts
    final offUrl = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$sanitized.json',
    );

    final http.Response response;
    try {
      response = await _httpClient
          .get(
            offUrl,
            headers: const {
              'User-Agent':
                  'NutriLensAI/1.0 (https://github.com/TobiShakur/nutrilens-ai-tracker)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const BarcodeTimeoutFailure();
    } on Exception catch (e) {
      LogSanitizer.logDebug(
        'BarcodeService',
        'Error de red al consultar Open Food Facts: $e',
      );
      throw const BarcodeRedFailure();
    }

    if (response.statusCode == 200) {
      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const BarcodeRespuestaInvalidaFailure();
      }

      if (decoded is Map<String, dynamic> && decoded['status'] == 1) {
        final product = decoded['product'];
        if (product is Map<String, dynamic>) {
          return _parsearOpenFoodFacts(
            product,
            sanitized,
            languageCode: languageCode,
          );
        }
      }
    } else if (response.statusCode == 429) {
      throw const BarcodeRateLimitFailure();
    } else if (response.statusCode >= 500) {
      throw BarcodeApiNoDisponibleFailure(statusCode: response.statusCode);
    } else if (response.statusCode != 404) {
      throw BarcodeApiNoDisponibleFailure(statusCode: response.statusCode);
    }

    // 2. Fallback opcional con Gemini solo cuando OFF no tiene el producto y hay proxy o clave
    if (_tieneGeminiDisponible) {
      return _consultarGeminiPorCodigo(sanitized, languageCode: languageCode);
    }

    return null;
  }

  @override
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
    String languageCode = 'es',
  }) async {
    final falloImagen = BarcodeValidator.validarImagenEtiqueta(bytes, mimeType);
    if (falloImagen != null) {
      throw BarcodeImagenInvalidaFailure(falloImagen);
    }

    if (!_tieneGeminiDisponible) {
      throw const BarcodeApiKeyFaltanteFailure();
    }

    final mimeNormalizado = BarcodeValidator.normalizarMime(mimeType);
    final base64Image = base64Encode(bytes);
    final isEnglish = languageCode.toLowerCase() == 'en';

    final prompt = isEnglish
        ? '''
You are a high-precision nutrition and computer vision system.
Analyze the provided image. It may be a photo of a food product barcode, front of package, or nutrition facts table.

TASKS:
1. Read the numeric barcode digits if visible or printed on the package.
2. Identify the exact product name (in English if generic, keeping commercial brand names intact) and main brand.
3. Extract the recommended serving size in grams or milliliters (e.g., 30, 40, 100). If the table only shows per 100g values, use 100.
4. Extract or calculate calories (Kcal), protein (g), carbohydrates (g), and fat (g) for that serving size.
5. Suggest the most fitting category ID ('proteinas', 'carbohidratos', 'lacteos', 'grasas', 'vegetales', 'otros').
'''
        : '''
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
              'inline_data': {
                'mime_type': mimeNormalizado,
                'data': base64Image,
              },
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'response_schema': _geminiProductSchema(incluirCodigoBarras: true),
      },
    });

    final response = await _postGeminiConRetrySelectivo(
      headers: _buildGeminiHeaders(),
      body: body,
      timeout: const Duration(seconds: 18),
    );

    final parsed = _extraerJsonProductoGemini(response.body);
    if (parsed == null) return null;

    return _construirProductoNormalizado(
      nombreRaw: parsed['nombre'],
      marcaRaw: parsed['marca'],
      porcionRaw: parsed['porcionGramos'],
      caloriasRaw: parsed['calorias'],
      proteinasRaw: parsed['proteinas'],
      carbosRaw: parsed['carbos'],
      grasasRaw: parsed['grasas'],
      categoriaRaw: parsed['categoriaSugerida'],
      codigoBarrasRaw: parsed['codigoBarras'],
      fuente: 'Gemini Vision AI',
    );
  }

  BarcodeProductData? _parsearOpenFoodFacts(
    Map<String, dynamic> product,
    String codigo, {
    String languageCode = 'es',
  }) {
    final nombreEs = (product['product_name_es'] as String?)?.trim() ?? '';
    final nombreEn = (product['product_name_en'] as String?)?.trim() ?? '';
    final nombreBase = (product['product_name'] as String?)?.trim() ?? '';
    final isEnglish = languageCode.toLowerCase() == 'en';
    final nombre = isEnglish
        ? (nombreEn.isNotEmpty
              ? nombreEn
              : nombreBase.isNotEmpty
              ? nombreBase
              : nombreEs.isNotEmpty
              ? nombreEs
              : 'Product $codigo')
        : (nombreEs.isNotEmpty
              ? nombreEs
              : nombreBase.isNotEmpty
              ? nombreBase
              : nombreEn.isNotEmpty
              ? nombreEn
              : 'Producto $codigo');

    final marca = (product['brands'] as String?)?.split(',').first.trim() ?? '';

    var porcion = 100.0;
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
    if (!porcion.isFinite || porcion <= 0) {
      porcion = 100.0;
    } else {
      porcion = porcion.clamp(1.0, 10000.0).toDouble();
    }

    final nutrimentsRaw = product['nutriments'];
    final nutriments = nutrimentsRaw is Map<String, dynamic>
        ? nutrimentsRaw
        : const <String, dynamic>{};

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

    if (cal <= 0 && nutriments['energy_100g'] != null) {
      cal = (_toDouble(nutriments['energy_100g']) / 4.184) * (porcion / 100.0);
    }

    final calNormalizadas = cal.isFinite ? cal.clamp(0.0, 10000.0).round() : 0;

    return _construirProductoNormalizado(
      nombreRaw: nombre,
      marcaRaw: marca,
      porcionRaw: porcion,
      caloriasRaw: calNormalizadas,
      proteinasRaw: prot,
      carbosRaw: carb,
      grasasRaw: gras,
      codigoBarrasRaw: codigo,
      fuente: 'Open Food Facts',
    );
  }

  Future<BarcodeProductData?> _consultarGeminiPorCodigo(
    String codigo, {
    String languageCode = 'es',
  }) async {
    if (!_tieneGeminiDisponible) return null;

    final isEnglish = languageCode.toLowerCase() == 'en';
    final prompt = isEnglish
        ? '''
The user entered the numeric barcode: "$codigo".
If you recognize the food or packaged product associated with this EAN/UPC code, identify its product name (in English if generic), brand, standard serving size (in grams), and macros per serving.
If you are not completely certain, respond with null or an empty object.
'''
        : '''
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
        'response_schema': _geminiProductSchema(incluirCodigoBarras: false),
      },
    });

    final response = await _postGeminiConRetrySelectivo(
      headers: _buildGeminiHeaders(),
      body: body,
      timeout: const Duration(seconds: 10),
    );

    final parsed = _extraerJsonProductoGemini(response.body);
    if (parsed == null) return null;

    return _construirProductoNormalizado(
      nombreRaw: parsed['nombre'],
      marcaRaw: parsed['marca'],
      porcionRaw: parsed['porcionGramos'],
      caloriasRaw: parsed['calorias'],
      proteinasRaw: parsed['proteinas'],
      carbosRaw: parsed['carbos'],
      grasasRaw: parsed['grasas'],
      categoriaRaw: parsed['categoriaSugerida'],
      codigoBarrasRaw: codigo,
      fuente: 'Gemini AI Assistant',
    );
  }

  Map<String, String> _buildGeminiHeaders() {
    if (_usaProxy) {
      return const {'Content-Type': 'application/json'};
    }
    return {'Content-Type': 'application/json', 'x-goog-api-key': _geminiKey};
  }

  ({Uri primary, Uri fallback}) _resolveGeminiUris() {
    if (_usaProxy) {
      try {
        return ApiConstants.resolveGeminiProxyUris(_geminiProxyUrl)!;
      } on FormatException {
        throw const BarcodeRespuestaInvalidaFailure();
      }
    }
    return (primary: _geminiPrimaryUrl, fallback: _geminiFallbackUrl);
  }

  Future<http.Response> _postGeminiConRetrySelectivo({
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) async {
    final uris = _resolveGeminiUris();
    var debeReintentar = false;

    try {
      final response = await _httpClient
          .post(uris.primary, headers: headers, body: body)
          .timeout(timeout);

      if (response.statusCode == 200) return response;

      if (response.statusCode == 404 || response.statusCode >= 500) {
        debeReintentar = true;
      } else {
        _lanzarPorStatusHttp(response.statusCode, response.body);
      }
    } on TimeoutException {
      debeReintentar = true;
    } on BarcodeScanFailure {
      rethrow;
    } on Exception catch (e) {
      LogSanitizer.logDebug(
        'BarcodeService',
        'Error transitorio en Gemini primario: $e',
      );
      debeReintentar = true;
    }

    if (!debeReintentar) {
      throw const BarcodeApiNoDisponibleFailure();
    }

    try {
      final fallbackResponse = await _httpClient
          .post(uris.fallback, headers: headers, body: body)
          .timeout(timeout);

      if (fallbackResponse.statusCode == 200) return fallbackResponse;
      _lanzarPorStatusHttp(fallbackResponse.statusCode, fallbackResponse.body);
    } on TimeoutException {
      throw const BarcodeTimeoutFailure();
    } on BarcodeScanFailure {
      rethrow;
    } on Exception catch (e) {
      LogSanitizer.logDebug('BarcodeService', 'Error en fallback Gemini: $e');
      throw const BarcodeRedFailure();
    }
  }

  Never _lanzarPorStatusHttp(int statusCode, String responseBody) {
    LogSanitizer.logDebug(
      'BarcodeService',
      'Respuesta no exitosa de Gemini status=$statusCode',
      body: responseBody,
    );
    if (statusCode == 401 || statusCode == 403) {
      throw const BarcodeApiKeyFaltanteFailure();
    }
    if (statusCode == 429) {
      throw const BarcodeRateLimitFailure();
    }
    if (statusCode == 400) {
      throw const BarcodeRespuestaInvalidaFailure();
    }
    throw BarcodeApiNoDisponibleFailure(statusCode: statusCode);
  }

  Map<String, dynamic>? _extraerJsonProductoGemini(String responseBody) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(responseBody);
    } on FormatException {
      throw const BarcodeRespuestaInvalidaFailure();
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BarcodeRespuestaInvalidaFailure();
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) return null;

    final content = firstCandidate['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    final firstPart = parts.first;
    if (firstPart is! Map) return null;

    final text = firstPart['text'];
    if (text is! String || text.trim().isEmpty) return null;

    final dynamic parsed;
    try {
      parsed = jsonDecode(text);
    } on FormatException {
      throw const BarcodeRespuestaInvalidaFailure();
    }

    if (parsed is! Map<String, dynamic>) return null;
    return parsed;
  }

  BarcodeProductData? _construirProductoNormalizado({
    required dynamic nombreRaw,
    dynamic marcaRaw,
    required dynamic porcionRaw,
    required dynamic caloriasRaw,
    required dynamic proteinasRaw,
    required dynamic carbosRaw,
    required dynamic grasasRaw,
    dynamic categoriaRaw,
    dynamic codigoBarrasRaw,
    required String fuente,
  }) {
    if (nombreRaw is! String || nombreRaw.trim().isEmpty) {
      return null;
    }

    return BarcodeProductData.normalizar(
      nombre: nombreRaw,
      marca: marcaRaw is String ? marcaRaw : '',
      porcionGramos: _toDouble(porcionRaw, fallback: 100.0),
      calorias: _toInt(caloriasRaw, fallback: 0),
      proteinas: _toDouble(proteinasRaw, fallback: 0.0),
      carbohidratos: _toDouble(carbosRaw, fallback: 0.0),
      grasas: _toDouble(grasasRaw, fallback: 0.0),
      categoriaIdSugerida: categoriaRaw is String ? categoriaRaw : null,
      codigoBarras: codigoBarrasRaw is String ? codigoBarrasRaw : null,
      fuente: fuente,
    );
  }

  static Map<String, dynamic> _geminiProductSchema({
    required bool incluirCodigoBarras,
  }) {
    return {
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
        if (incluirCodigoBarras) 'codigoBarras': {'type': 'STRING'},
      },
      'required': [
        'nombre',
        'porcionGramos',
        'calorias',
        'proteinas',
        'carbos',
        'grasas',
      ],
    };
  }

  static double _toDouble(dynamic val, {double fallback = 0.0}) {
    if (val == null) return fallback;
    final double? parsed = switch (val) {
      num n => n.toDouble(),
      String s => double.tryParse(s.trim().replaceAll(',', '.')),
      _ => null,
    };
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed;
  }

  static int _toInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    final double? parsed = switch (val) {
      int i => i.toDouble(),
      num n => n.toDouble(),
      String s => double.tryParse(s.trim().replaceAll(',', '.')),
      _ => null,
    };
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed.round();
  }
}
