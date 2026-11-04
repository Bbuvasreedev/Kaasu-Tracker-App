import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ApiService authentication', () {
    test('sends the Supabase access token as a bearer token', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });
      final service = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        accessTokenProvider: () => 'test-access-token',
      );

      await service.get('users/me');

      expect(
        capturedRequest!.headers['authorization'],
        'Bearer test-access-token',
      );
      expect(capturedRequest!.url.path, '/api/v1/users/me');
      client.close();
    });

    test(
      'preserves the API prefix when the base URL has no trailing slash',
      () async {
        http.Request? capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        });
        final service = ApiService(
          client: client,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('https://api.example.test/api/v1'),
          accessTokenProvider: () => 'test-access-token',
        );

        await service.get(
          'finance/monthly-summary',
          queryParameters: {'year': 2026, 'month': 11},
        );

        expect(
          capturedRequest!.url.toString(),
          'https://api.example.test/api/v1/finance/monthly-summary'
          '?year=2026&month=11',
        );
        expect(capturedRequest!.headers['content-type'], 'application/json');
        client.close();
      },
    );

    test('rejects protected requests without a session token', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final service = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        accessTokenProvider: () => null,
      );

      await expectLater(
        service.get('users/me'),
        throwsA(isA<ApiAuthenticationException>()),
      );
      client.close();
    });

    test('parses backend errors without retrying an expired session', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('{"status":401,"message":"Token expired"}', 401);
      });
      final service = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        accessTokenProvider: () => 'test-access-token',
      );

      await expectLater(
        service.get('finance/monthly-summary'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.message, 'message', 'Token expired'),
        ),
      );
      expect(requestCount, 1);
      client.close();
    });

    test('debug error logging redacts credentials and tokens', () async {
      final previousDebugPrint = debugPrint;
      final loggedMessages = <String>[];
      debugPrint = (message, {wrapWidth}) {
        loggedMessages.add(message ?? '');
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      final client = MockClient(
        (_) async => http.Response(
          '{"message":"Denied","accessToken":"sensitive-token",'
          '"authorization":"Bearer private-bearer",'
          '"details":"Bearer another-private-token"}',
          403,
        ),
      );
      final service = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        accessTokenProvider: () => 'test-access-token',
      );

      await expectLater(service.get('emis'), throwsA(isA<ApiException>()));

      final logged = loggedMessages.join('\n');
      expect(logged, contains('HTTP 403'));
      expect(logged, contains('[REDACTED]'));
      expect(logged, isNot(contains('sensitive-token')));
      expect(logged, isNot(contains('private-bearer')));
      expect(logged, isNot(contains('another-private-token')));
      client.close();
    });

    test('includes backend validation details for bad requests', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"status":400,"message":"Request validation failed",'
          '"validationErrors":[{"field":"amount","message":"must be positive"}]}',
          400,
        ),
      );
      final service = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        accessTokenProvider: () => 'test-access-token',
      );

      await expectLater(
        service.get('additional-funds'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Request validation failed (amount: must be positive)',
          ),
        ),
      );
      client.close();
    });
  });
}
