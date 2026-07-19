import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/imported_shopping_item.dart';
import 'shopping_list_interpreter.dart';

class RemoteShoppingListInterpreter implements ShoppingListInterpreter {
  const RemoteShoppingListInterpreter({
    required this.endpoint,
    required this.fallback,
    http.Client? client,
  }) : _client = client;

  final Uri endpoint;
  final ShoppingListInterpreter fallback;
  final http.Client? _client;

  @override
  Future<List<ImportedShoppingItem>> interpret(String rawText) async {
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response = await client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rawText': rawText}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback.interpret(rawText);
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      final rawItems = payload is Map<String, dynamic> ? payload['items'] : null;
      if (rawItems is! List) {
        return fallback.interpret(rawText);
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => _itemFromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.name.trim().isNotEmpty)
          .toList();

      if (items.isEmpty) {
        return await fallback.interpret(rawText);
      }
      return items;
    } catch (_) {
      return fallback.interpret(rawText);
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
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
