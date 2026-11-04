import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum ReceiptSource { camera, gallery, document }

class ReceiptFile {
  const ReceiptFile({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String extension;

  bool get isPdf => extension.toLowerCase() == 'pdf';
}

class ReceiptAnalysis {
  const ReceiptAnalysis({
    this.amount,
    this.category,
    this.description,
    this.merchant,
    this.expenseDate,
    this.subtotal,
    this.tax,
    this.discount,
    this.currency,
    this.paymentMethod,
    this.invoiceNumber,
    this.items = const [],
  });

  final double? amount;
  final String? category;
  final String? description;
  final String? merchant;
  final DateTime? expenseDate;
  final double? subtotal;
  final double? tax;
  final double? discount;
  final String? currency;
  final String? paymentMethod;
  final String? invoiceNumber;
  final List<ReceiptItem> items;

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) {
    return ReceiptAnalysis(
      amount: _number(json['amount']),
      category: _nonEmptyString(json['category']),
      description: _nonEmptyString(json['description']),
      merchant: _nonEmptyString(json['merchant']),
      expenseDate: _date(json['expenseDate']),
      subtotal: _number(json['subtotal']),
      tax: _number(json['tax'] ?? json['gst']),
      discount: _number(json['discount']),
      currency: _nonEmptyString(json['currency']),
      paymentMethod: _nonEmptyString(json['paymentMethod']),
      invoiceNumber: _nonEmptyString(
        json['invoiceNumber'] ?? json['receiptNumber'],
      ),
      items: _items(json['items']),
    );
  }

  static double? _number(Object? value) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value.trim())
        : null;
    return number != null && number.isFinite ? number : null;
  }

  static String? _nonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static DateTime? _date(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  static List<ReceiptItem> _items(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) {
          final name = _nonEmptyString(item['name']);
          if (name == null) return null;
          return ReceiptItem(name: name, price: _number(item['price']));
        })
        .whereType<ReceiptItem>()
        .toList(growable: false);
  }
}

class ReceiptItem {
  const ReceiptItem({required this.name, this.price});

  final String name;
  final double? price;
}

class ReceiptPickerException implements Exception {
  const ReceiptPickerException(
    this.message, {
    this.canOpenSettings = false,
    this.isPermissionDenied = false,
  });

  final String message;
  final bool canOpenSettings;
  final bool isPermissionDenied;
}

enum ReceiptFileIssue { empty, tooLarge, unsupported, invalid, pdfUnsupported }

class ReceiptFileException implements Exception {
  const ReceiptFileException(this.issue);

  final ReceiptFileIssue issue;
}

abstract interface class ReceiptMediaPicker {
  Future<ReceiptFile?> pick(ReceiptSource source);
}

class DeviceReceiptMediaPicker implements ReceiptMediaPicker {
  DeviceReceiptMediaPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<ReceiptFile?> pick(ReceiptSource source) async {
    if (source == ReceiptSource.document) {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (file == null) return null;
      final size = await file.length();
      if (size == null) {
        throw const ReceiptPickerException('Could not read the selected file.');
      }
      if (size > ReceiptScanner.maxFileBytes) {
        throw const ReceiptFileException(ReceiptFileIssue.tooLarge);
      }
      final bytes = await file.xFile.readAsBytes();
      return ReceiptFile(
        name: file.name,
        bytes: bytes,
        extension: file.extension ?? '',
      );
    }

    if (source == ReceiptSource.camera) {
      final permission = await Permission.camera.status;
      final result = permission.isGranted
          ? permission
          : permission.isPermanentlyDenied || permission.isRestricted
          ? permission
          : await Permission.camera.request();
      if (!result.isGranted) {
        throw ReceiptPickerException(
          result.isPermanentlyDenied || result.isRestricted
              ? 'Camera permission is blocked in system settings.'
              : 'Camera permission was denied.',
          canOpenSettings: result.isPermanentlyDenied || result.isRestricted,
          isPermissionDenied: true,
        );
      }
    }

    final XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: source == ReceiptSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
    } on PlatformException catch (error) {
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('restricted');
      throw ReceiptPickerException(
        error.code.toLowerCase().contains('permanently')
            ? 'Permission is blocked in system settings.'
            : 'Permission to select the receipt was denied.',
        canOpenSettings: error.code.toLowerCase().contains('permanently'),
        isPermissionDenied: denied,
      );
    }
    if (image == null) return null;
    return ReceiptFile(
      name: image.name,
      bytes: await image.readAsBytes(),
      extension: image.name.split('.').last.toLowerCase(),
    );
  }
}

class ReceiptScanner {
  const ReceiptScanner(this._api);

  static const maxFileBytes = 10 * 1024 * 1024;
  final ApiService _api;

  Future<ReceiptAnalysis> analyze(ReceiptFile file) async {
    await validate(file);
    if (file.isPdf) {
      throw const ReceiptFileException(ReceiptFileIssue.pdfUnsupported);
    }
    final response = await _api.analyzeReceipt(base64Encode(file.bytes));
    return ReceiptAnalysis.fromJson(response);
  }

  Future<void> validate(ReceiptFile file) async {
    if (file.bytes.isEmpty) {
      throw const ReceiptFileException(ReceiptFileIssue.empty);
    }
    if (file.bytes.length > maxFileBytes) {
      throw const ReceiptFileException(ReceiptFileIssue.tooLarge);
    }
    if (file.isPdf) {
      if (!_isPdf(file.bytes)) {
        throw const ReceiptFileException(ReceiptFileIssue.invalid);
      }
      return;
    }

    final extension = file.extension.toLowerCase();
    final isSupportedExtension = const {
      'jpg',
      'jpeg',
      'png',
      'webp',
    }.contains(extension);
    if (!isSupportedExtension) {
      throw const ReceiptFileException(ReceiptFileIssue.unsupported);
    }
    if (!_matchesImageType(file.bytes, extension)) {
      throw const ReceiptFileException(ReceiptFileIssue.invalid);
    }
    try {
      final codec = await ui.instantiateImageCodec(file.bytes);
      codec.dispose();
    } on Object {
      throw const ReceiptFileException(ReceiptFileIssue.invalid);
    }
  }

  bool _isPdf(Uint8List bytes) =>
      bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';

  bool _matchesImageType(Uint8List bytes, String extension) {
    if (extension == 'jpg' || extension == 'jpeg') {
      return bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff;
    }
    if (extension == 'png') {
      return bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0d &&
          bytes[5] == 0x0a &&
          bytes[6] == 0x1a &&
          bytes[7] == 0x0a;
    }
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
  }
}

final receiptMediaPickerProvider = Provider<ReceiptMediaPicker>(
  (ref) => DeviceReceiptMediaPicker(),
);

final receiptScannerProvider = Provider<ReceiptScanner>(
  (ref) => ReceiptScanner(ref.watch(apiServiceProvider)),
);
