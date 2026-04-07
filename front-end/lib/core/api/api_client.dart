import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient({String? baseUrl, String? accessToken})
      : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), ''),
        _accessToken = accessToken;

  final String _baseUrl;
  final String? _accessToken;

  Map<String, String> _defaultHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      ...?extraHeaders,
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _uri(path);
    final res = await http
        .post(
          uri,
          headers: _defaultHeaders(extraHeaders: {
            'Content-Type': 'application/json',
          }),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _uri(path);
    final res = await http
        .put(
          uri,
          headers: _defaultHeaders(extraHeaders: {
            'Content-Type': 'application/json',
          }),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final uri = _uri(path);
    final res = await http
        .delete(
          uri,
          headers: _defaultHeaders(),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> postEmpty(
    String path, {
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final res = await http
        .post(
          uri,
          headers: _defaultHeaders(extraHeaders: extraHeaders),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = _uri(path);
    final res = await http
        .get(
          uri,
          headers: _defaultHeaders(),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(res);
  }

  /// Réponses JSON qui sont un **tableau** en racine : le client les enveloppe en `{ "data": [...] }`.
  Future<List<dynamic>> getJsonList(String path) async {
    final m = await getJson(path);
    final d = m['data'];
    if (d is List<dynamic>) return d;
    if (d is List) return List<dynamic>.from(d);
    return const [];
  }

  Future<Map<String, dynamic>> postMultipartImage({
    required String path,
    required Uint8List imageBytes,
    required String observationDate, // YYYY-MM-DD
    Map<String, String>? fields,
    String fileFieldName = 'file',
    String fileName = 'lesion.jpg',
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_defaultHeaders());
    request.fields['observation_date'] = observationDate;
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        imageBytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final bodyBytes = await streamed.stream.toBytes();

    final res = http.Response.bytes(bodyBytes, streamed.statusCode);
    return _handleResponse(res);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final status = res.statusCode;
    final raw = res.body.trim();
    if (status >= 200 && status < 300) {
      if (raw.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    }

    String message = 'Erreur HTTP';
    try {
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          message = decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              message;
        }
      }
    } catch (_) {
      // ignore decode errors
    }

    throw ApiException(message: message, statusCode: status);
  }
}
