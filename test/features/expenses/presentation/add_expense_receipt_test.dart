import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/receipt_scanner.dart';
import 'package:kaasutracker/features/expenses/presentation/add_expense_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('gallery picker cancellation leaves the form unchanged', (
    tester,
  ) async {
    final picker = _FakeMediaPicker(null);
    await _pumpScreen(tester, picker: picker);

    await _openSource(tester, 'Choose from Gallery');

    expect(picker.sources, [ReceiptSource.gallery]);
    expect(find.text('Receipt preview'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('document picker cancellation leaves the form unchanged', (
    tester,
  ) async {
    final picker = _FakeMediaPicker(null);
    await _pumpScreen(tester, picker: picker);

    await _openSource(tester, 'Choose Document');

    expect(picker.sources, [ReceiptSource.document]);
    expect(find.text('Receipt preview'), findsNothing);
  });

  testWidgets('camera permission denial shows guidance and preserves form', (
    tester,
  ) async {
    final picker = _FakeMediaPicker(
      null,
      error: const ReceiptPickerException('denied', isPermissionDenied: true),
    );
    await _pumpScreen(tester, picker: picker);

    await _openSource(tester, 'Take a Photo (Camera)');

    expect(
      find.text(
        'Camera access was denied. Allow camera access to take a receipt photo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Receipt preview'), findsNothing);
  });

  testWidgets('review values are editable and analysis cannot submit twice', (
    tester,
  ) async {
    final picker = _FakeMediaPicker(_pngReceipt);
    final analysisResponse = Completer<http.Response>();
    var analysisRequests = 0;
    await _pumpScreen(
      tester,
      picker: picker,
      handler: (request) {
        if (request.url.path.endsWith('/expenses/analyze')) {
          analysisRequests++;
          return analysisResponse.future;
        }
        return Future.value(http.Response('{}', 200));
      },
    );

    await _openSource(tester, 'Choose from Gallery');
    expect(find.text('Receipt preview'), findsOneWidget);
    await tester.ensureVisible(find.text('Analyze receipt'));
    await tester.tap(find.text('Analyze receipt'));
    await tester.pump();
    expect(analysisRequests, 1);
    expect(
      tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Analyze receipt'),
          matching: find.byType(FilledButton),
        ),
      ).onPressed,
      isNull,
    );
    expect(analysisRequests, 1);

    analysisResponse.complete(
      http.Response(
        jsonEncode({
          'amount': 72.5,
          'merchant': 'Corner Shop',
          'category': 'Food',
          'expenseDate': '2026-10-25',
          'tax': 2.5,
          'paymentMethod': 'UPI',
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'AI suggestions are unverified. Review and edit the expense fields before saving.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Tax/GST: 2.5'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '99.00');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Corrected shop name',
    );
    expect(find.text('99.00'), findsOneWidget);
    expect(find.text('Corrected shop name'), findsOneWidget);
  });

  testWidgets('analysis failure displays retry and a retry makes a new request', (
    tester,
  ) async {
    final picker = _FakeMediaPicker(_pngReceipt);
    var requests = 0;
    await _pumpScreen(
      tester,
      picker: picker,
      handler: (request) async {
        if (request.url.path.endsWith('/expenses/analyze')) {
          requests++;
          if (requests == 1) {
            return http.Response('Unavailable', 503);
          }
          return http.Response(jsonEncode({'amount': 42}), 200);
        }
        return http.Response('{}', 200);
      },
    );

    await _openSource(tester, 'Choose from Gallery');
    await tester.ensureVisible(find.text('Analyze receipt'));
    await tester.tap(find.text('Analyze receipt'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not analyze this receipt. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(
      find.text(
        'Could not analyze this receipt. Check your connection and try again.',
      ),
      findsNothing,
    );
    expect(find.text('42.00'), findsOneWidget);
  });
}

Future<void> _openSource(WidgetTester tester, String choice) async {
  await tester.tap(find.text('Scan Receipt'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice));
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeMediaPicker picker,
  Future<http.Response> Function(http.Request)? handler,
}) async {
  final api = _api(handler ?? (_) async => http.Response('{}', 200));
  addTearDown(api.client.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        receiptMediaPickerProvider.overrideWithValue(picker),
        apiServiceProvider.overrideWithValue(api),
      ],
      child: const MaterialApp(
        home: AddExpenseScreen(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeMediaPicker implements ReceiptMediaPicker {
  _FakeMediaPicker(this.file, {this.error});

  final ReceiptFile? file;
  final ReceiptPickerException? error;
  final sources = <ReceiptSource>[];

  @override
  Future<ReceiptFile?> pick(ReceiptSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return file;
  }
}

final _pngReceipt = ReceiptFile(
  name: 'receipt.png',
  extension: 'png',
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

ApiService _api(Future<http.Response> Function(http.Request) handler) =>
    ApiService(
      client: MockClient(handler),
      supabase: SupabaseClient(
        'http://localhost:54321',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
      baseUrl: Uri.parse('https://api.example.test/api/v1/'),
      accessTokenProvider: () => 'test-token',
    );
