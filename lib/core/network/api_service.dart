import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'api_service.g.dart';

class ApiService {
  ApiService({required this.client, required this.supabase, Uri? baseUrl})
      : _baseUrl = baseUrl ?? Uri.parse('http://10.0.2.2:8080/api/v1/');

  final http.Client client;
  final SupabaseClient supabase;
  final Uri _baseUrl;

  Future<dynamic> get(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    final response = await client.get(
      _uriFor(path, queryParameters: queryParameters),
      headers: await _headers(),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> post(
      String path, {
        required Object body,
        Map<String, dynamic>? queryParameters,
      }) async {
    final response = await client.post(
      _uriFor(path, queryParameters: queryParameters),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
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
        ...queryParameters.map(
              (key, value) => MapEntry(key, value.toString()),
        ),
      },
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('A signed-in Supabase session is required.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccessful) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'API request failed ($statusCode): $message';
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