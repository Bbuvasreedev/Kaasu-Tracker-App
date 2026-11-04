import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/receipt_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses only values actually supplied by receipt analysis', () {
    final analysis = ReceiptAnalysis.fromJson({
      'amount': '45.75',
      'merchant': 'Corner Shop',
      'expenseDate': '2026-10-25',
      'gst': 2.5,
      'paymentMethod': 'UPI',
      'receiptNumber': 'INV-9',
      'items': [
        {'name': 'Tea', 'price': '10.00'},
      ],
    });

    expect(analysis.amount, 45.75);
    expect(analysis.merchant, 'Corner Shop');
    expect(analysis.expenseDate, DateTime(2026, 10, 25));
    expect(analysis.tax, 2.5);
    expect(analysis.paymentMethod, 'UPI');
    expect(analysis.invoiceNumber, 'INV-9');
    expect(analysis.items.single.name, 'Tea');
    expect(analysis.subtotal, isNull);
    expect(analysis.category, isNull);
    expect(analysis.discount, isNull);
  });

  test('rejects empty, oversized, unsupported, and corrupt files', () async {
    final scanner = ReceiptScanner(_api((_) async => http.Response('{}', 200)));

    await expectLater(
      scanner.validate(_file('empty.png', Uint8List(0))),
      throwsA(
        isA<ReceiptFileException>().having(
          (error) => error.issue,
          'issue',
          ReceiptFileIssue.empty,
        ),
      ),
    );
    await expectLater(
      scanner.validate(
        _file('large.jpg', Uint8List(ReceiptScanner.maxFileBytes + 1)),
      ),
      throwsA(
        isA<ReceiptFileException>().having(
          (error) => error.issue,
          'issue',
          ReceiptFileIssue.tooLarge,
        ),
      ),
    );
    await expectLater(
      scanner.validate(_file('receipt.txt', Uint8List.fromList([1, 2, 3]))),
      throwsA(
        isA<ReceiptFileException>().having(
          (error) => error.issue,
          'issue',
          ReceiptFileIssue.unsupported,
        ),
      ),
    );
    await expectLater(
      scanner.validate(_file('broken.png', Uint8List.fromList([1, 2, 3]))),
      throwsA(
        isA<ReceiptFileException>().having(
          (error) => error.issue,
          'issue',
          ReceiptFileIssue.invalid,
        ),
      ),
    );
  });

  test('does not send PDFs to the image-only analysis endpoint', () async {
    var requests = 0;
    final scanner = ReceiptScanner(
      _api((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      scanner.analyze(
        _file('receipt.pdf', Uint8List.fromList(ascii.encode('%PDF-1.7'))),
      ),
      throwsA(
        isA<ReceiptFileException>().having(
          (error) => error.issue,
          'issue',
          ReceiptFileIssue.pdfUnsupported,
        ),
      ),
    );
    expect(requests, 0);
  });

  test(
    'posts supported image as base64 and parses extraction response',
    () async {
      http.Request? captured;
      final scanner = ReceiptScanner(
        _api((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'amount': 81.5,
              'merchant': 'Market',
              'category': 'Food',
            }),
            200,
          );
        }),
      );
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );

      final analysis = await scanner.analyze(_file('receipt.png', bytes));

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/expenses/analyze');
      expect(jsonDecode(captured!.body), {'base64Image': base64Encode(bytes)});
      expect(analysis.amount, 81.5);
      expect(analysis.merchant, 'Market');
    },
  );

  test(
    'surfaces analysis server errors without returning fabricated data',
    () async {
      final scanner = ReceiptScanner(
        _api((_) async => http.Response('Service unavailable', 503)),
      );
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );

      await expectLater(
        scanner.analyze(_file('receipt.png', bytes)),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            503,
          ),
        ),
      );
    },
  );
}

ReceiptFile _file(String name, Uint8List bytes) =>
    ReceiptFile(name: name, extension: name.split('.').last, bytes: bytes);

ApiService _api(Future<http.Response> Function(http.Request) handler) =>
    ApiService(
      client: MockClient(handler),
      supabase: SupabaseClient('http://localhost:54321', 'anon-key'),
      baseUrl: Uri.parse('https://api.example.test/api/v1/'),
      accessTokenProvider: () => 'test-token',
    );
