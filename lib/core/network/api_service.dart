import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'api_service.g.dart';

class ApiService {
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1/',
  );

  ApiService({
    required this.client,
    required this.supabase,
    Uri? baseUrl,
    String? Function()? accessTokenProvider,
  }) : _baseUrl = _withTrailingSlash(baseUrl ?? Uri.parse(_defaultBaseUrl)),
       _accessTokenProvider =
           accessTokenProvider ??
           (() => supabase.auth.currentSession?.accessToken);

  final http.Client client;
  final SupabaseClient supabase;
  final Uri _baseUrl;
  final String? Function() _accessTokenProvider;

  static Uri _withTrailingSlash(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: '${uri.path}/');
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      client.get(
        _uriFor(path, queryParameters: queryParameters),
        headers: await _headers(),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    required Object body,
    Map<String, dynamic>? queryParameters,
    bool logErrorDetails = true,
  }) async {
    return _send(
      client.post(
        _uriFor(path, queryParameters: queryParameters),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
      logErrorDetails: logErrorDetails,
    );
  }

  Future<dynamic> postWithoutBody(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      client.post(
        _uriFor(path, queryParameters: queryParameters),
        headers: await _headers(),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    required Object body,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      client.put(
        _uriFor(path, queryParameters: queryParameters),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(String path) async {
    return _send(client.delete(_uriFor(path), headers: await _headers()));
  }

  /// Sends a base64 encoded receipt image to the backend `/expenses/analyze` endpoint.
  Future<Map<String, dynamic>> analyzeReceipt(String base64Image) async {
    final response = await post(
      'expenses/analyze',
      body: {'base64Image': base64Image},
      logErrorDetails: false,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const FormatException(
      'Invalid response format from analyze endpoint.',
    );
  }

  Uri _uriFor(String path, {Map<String, dynamic>? queryParameters}) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final resolvedUri = _baseUrl.resolve(cleanPath);

    if (queryParameters == null || queryParameters.isEmpty) {
      return resolvedUri;
    }

    return resolvedUri.replace(
      queryParameters: {
        ...resolvedUri.queryParameters,
        ...queryParameters.map((key, value) => MapEntry(key, value.toString())),
      },
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const ApiAuthenticationException();
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(
    Future<http.Response> request, {
    bool logErrorDetails = true,
  }) async {
    final response = await request.timeout(const Duration(seconds: 20));
    return _decodeResponse(response, logErrorDetails: logErrorDetails);
  }

  dynamic _decodeResponse(
    http.Response response, {
    bool logErrorDetails = true,
  }) {
    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccessful) {
      if (kDebugMode) {
        final details = logErrorDetails
            ? ': ${_sanitizeErrorForDebug(response.body)}'
            : '';
        debugPrint('API request failed (HTTP ${response.statusCode})$details');
      }
      var message = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final apiMessage = decoded['message'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage;
          }
          final validationErrors = decoded['validationErrors'];
          if (validationErrors is List) {
            final details = validationErrors
                .whereType<Map>()
                .map((error) {
                  final field = error['field'];
                  final detail = error['message'];
                  if (field is String && detail is String) {
                    return '$field: $detail';
                  }
                  return detail is String ? detail : null;
                })
                .whereType<String>()
                .toList(growable: false);
            if (details.isNotEmpty) {
              message = '$message (${details.join('; ')})';
            }
          }
        }
      } on FormatException {
        // Keep the response body for non-JSON errors.
      }
      throw ApiException(statusCode: response.statusCode, message: message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  String _sanitizeErrorForDebug(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return _truncateDebugBody(_redactBearerTokens(body));
    }

    return _truncateDebugBody(jsonEncode(_redactSensitiveValues(decoded)));
  }

  dynamic _redactSensitiveValues(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final keyString = key.toString();
        final isSensitive = RegExp(
          r'(?:access[_-]?token|refresh[_-]?token|authorization|password|secret|api[_-]?key)',
          caseSensitive: false,
        ).hasMatch(keyString);
        return MapEntry(
          keyString,
          isSensitive ? '[REDACTED]' : _redactSensitiveValues(nestedValue),
        );
      });
    }
    if (value is List) {
      return value.map(_redactSensitiveValues).toList(growable: false);
    }
    if (value is String) return _redactBearerTokens(value);
    return value;
  }

  String _redactBearerTokens(String value) => value.replaceAll(
    RegExp(r'Bearer\s+[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
    'Bearer [REDACTED]',
  );

  String _truncateDebugBody(String value) =>
      value.length <= 1000 ? value : '${value.substring(0, 1000)}…';
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'API request failed ($statusCode): $message';
}

class ApiAuthenticationException implements Exception {
  const ApiAuthenticationException();

  @override
  String toString() => 'A signed-in Supabase session is required.';
}

@riverpod
ApiService apiService(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return ApiService(
    client: client,
    supabase: ref.watch(supabaseClientProvider),
  );
}
