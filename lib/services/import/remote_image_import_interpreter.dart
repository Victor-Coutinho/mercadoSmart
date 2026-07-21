import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/imported_shopping_item.dart';
import 'image_import_interpreter.dart';

class RemoteImageImportInterpreter implements ImageImportInterpreter {
  const RemoteImageImportInterpreter({
    required this.endpoint,
    http.Client? client,
  }) : _client = client;

  final Uri endpoint;
  final http.Client? _client;

  @override
  Future<ImageImportInterpretation> interpretImage(XFile image) async {
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final bytes = await image.readAsBytes();
      final response = await client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageBase64': base64Encode(bytes),
          'mimeType': _mimeTypeFor(image),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ImageImportInterpretation(rawText: '', items: []);
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic>) {
        return const ImageImportInterpretation(rawText: '', items: []);
      }

      final rawItems = payload['items'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => _itemFromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.name.trim().isNotEmpty)
              .toList()
          : <ImportedShoppingItem>[];

      return ImageImportInterpretation(
        rawText: _readString(payload['rawText'] ?? payload['text']),
        items: items,
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  static String _mimeTypeFor(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) {
      return mimeType;
    }

    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  static ImportedShoppingItem _itemFromJson(Map<String, dynamic> json) {
    return ImportedShoppingItem(
      name: _readString(json['name'] ?? json['produto'] ?? json['product']),
      quantity: _readDouble(
        json['quantity'] ?? json['quantidade'] ?? json['qtd'],
        fallback: 1,
      ),
      unitPrice: _readDouble(
        json['unitPrice'] ??
            json['precoUnitario'] ??
            json['preco'] ??
            json['price'],
      ),
      sectionName: _readString(
        json['sectionName'] ??
            json['section'] ??
            json['secao'] ??
            json['categoria'],
        fallback: 'Mercearia',
      ),
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final direct = double.tryParse(value.replaceAll(',', '.'));
      if (direct != null) {
        return direct;
      }
      final match = RegExp(r'\d+(?:[,.]\d+)?').firstMatch(value);
      if (match != null) {
        return double.tryParse(match.group(0)!.replaceAll(',', '.')) ??
            fallback;
      }
    }
    return fallback;
  }
}
