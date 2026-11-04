import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('parses persisted duration and installment progress', () {
    final emi = EmiModel.fromJson({
      'id': 42,
      'title': 'Vehicle loan',
      'amount': 7500,
      'dueDateDay': 31,
      'startDate': '2025-01-15',
      'durationMonths': 24.0,
      'endDate': '2026-12-31',
      'status': 'ACTIVE',
      'totalInstallments': 24,
      'paidInstallments': '8',
      'remainingInstallments': 16,
    });

    expect(emi.id, '42');
    expect(emi.amount, 7500);
    expect(emi.startDate, DateTime(2025, 1, 15));
    expect(emi.durationMonths, 24);
    expect(emi.endDate, DateTime(2026, 12, 31));
    expect(emi.isActive, isTrue);
    expect(emi.isCompleted, isFalse);
    expect(emi.totalInstallments, 24);
    expect(emi.paidInstallments, 8);
    expect(emi.remainingInstallments, 16);
  });

  test(
    'keeps older EMI records compatible and ignores invalid optional data',
    () {
      final emi = EmiModel.fromJson({
        'id': 'old',
        'title': 'Existing loan',
        'amount': '1200.50',
        'dueDateDay': 10,
        'active': false,
        'startDate': 'not-a-date',
        'durationMonths': 12.5,
        'paidInstallments': 'unknown',
      });

      expect(emi.isActive, isFalse);
      expect(emi.startDate, isNull);
      expect(emi.durationMonths, isNull);
      expect(emi.paidInstallments, isNull);
      expect(emi.isCompleted, isFalse);
    },
  );

  test('recognizes completed EMIs from persisted status or payment counts', () {
    final byStatus = EmiModel.fromJson({
      'id': 'a',
      'title': 'Completed by status',
      'amount': 100,
      'dueDateDay': 1,
      'status': 'COMPLETED',
    });
    final byCounts = EmiModel.fromJson({
      'id': 'b',
      'title': 'Completed by counts',
      'amount': 100,
      'dueDateDay': 1,
      'totalInstallments': 6,
      'paidInstallments': 6,
      'remainingInstallments': 0,
    });

    expect(byStatus.isCompleted, isTrue);
    expect(byCounts.isCompleted, isTrue);
  });

  test(
    'status update uses the backend status endpoint and status DTO',
    () async {
      final requests = <http.Request>[];
      var isActive = true;
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'PUT') {
          isActive = jsonDecode(request.body)['status'] == 'ACTIVE';
          return http.Response(
            jsonEncode({'status': isActive ? 'ACTIVE' : 'INACTIVE'}),
            200,
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 42,
                'title': 'Car loan',
                'amount': 12500,
                'dueDateDay': 31,
                'isActive': isActive,
                'status': isActive ? 'ACTIVE' : 'INACTIVE',
              },
            ]),
            200,
          );
        }
        return http.Response('', 204);
      });
      final api = ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'anon-key'),
        baseUrl: Uri.parse('https://api.example.test/api/v1/'),
        accessTokenProvider: () => 'access-token',
      );
      final repository = EmiRepository(api);
      addTearDown(client.close);

      await repository.addEmi(
        title: 'Car loan',
        amount: 12500,
        dueDateDay: 31,
        startDate: DateTime(2026, 1, 3),
        durationMonths: 36,
      );
      await repository.updateEmiStatus(id: '42', isActive: false);
      final refreshedResponse = await api.get('emis') as List<dynamic>;
      final refreshedEmi = EmiModel.fromJson(
        refreshedResponse.single as Map<String, dynamic>,
      );

      expect(requests, hasLength(3));
      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/v1/emis');
      expect(jsonDecode(requests[0].body), {
        'title': 'Car loan',
        'amount': 12500,
        'dueDateDay': 31,
        'isActive': true,
        'startDate': '2026-01-03',
        'durationMonths': 36,
      });
      expect(requests[1].method, 'PUT');
      expect(requests[1].url.path, '/api/v1/emis/42/status');
      expect(jsonDecode(requests[1].body), {'status': 'INACTIVE'});
      expect(requests[2].method, 'GET');
      expect(requests[2].url.path, '/api/v1/emis');
      expect(refreshedEmi.isActive, isFalse);
    },
  );

  test('status update rejects non-numeric or non-positive EMI identifiers', () {
    final client = MockClient((_) async => http.Response('', 204));
    final repository = EmiRepository(
      ApiService(
        client: client,
        supabase: SupabaseClient('http://localhost:54321', 'anon-key'),
        accessTokenProvider: () => 'access-token',
      ),
    );
    addTearDown(client.close);

    expect(
      repository.updateEmiStatus(id: 'emi-42', isActive: false),
      throwsArgumentError,
    );
    expect(
      repository.updateEmiStatus(id: '0', isActive: false),
      throwsArgumentError,
    );
  });
}
