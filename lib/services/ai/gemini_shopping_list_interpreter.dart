import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/imported_shopping_item.dart';
import 'shopping_list_interpreter.dart';

class GeminiShoppingListInterpreter implements ShoppingListInterpreter {
  const GeminiShoppingListInterpreter({
    required this.apiKey,
    required this.fallback,
    this.model = 'gemini-2.5-flash-lite',
    http.Client? client,
  }) : _client = client;

  final String apiKey;
  final String model;
  final ShoppingListInterpreter fallback;
  final http.Client? _client;

  @override
  Future<List<ImportedShoppingItem>> interpret(String rawText) async {
    if (apiKey.trim().isEmpty) {
      return fallback.interpret(rawText);
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response = await client.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/interactions',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'model': model,
          'system_instruction': _systemInstruction,
          'input': _buildPrompt(rawText),
          'generation_config': {
            'temperature': 0.1,
          },
          'response_format': _responseFormat,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback.interpret(rawText);
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      final outputText = _extractOutputText(payload);
      if (outputText == null || outputText.trim().isEmpty) {
        return fallback.interpret(rawText);
      }

      final rawItems = _decodeItems(outputText);
      if (rawItems == null) {
        return fallback.interpret(rawText);
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => _itemFromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.name.trim().isNotEmpty)
          .toList();

      if (items.isEmpty) {
        return fallback.interpret(rawText);
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

  static const _systemInstruction = '''
Você é um assistente de supermercado do app MercadoSmart.
Sua tarefa é transformar texto de OCR de listas de compras em JSON válido.
Classifique cada item em uma seção curta de supermercado em português.
Use preferencialmente seções como Hortifruti, Açougue, Padaria, Frios, Limpeza, Higiene, Bebidas, Congelados ou Mercearia.
Não invente produtos que não apareçam no texto.
''';

  static String _buildPrompt(String rawText) {
    return '''
Extraia os produtos da lista abaixo.
Para cada produto, informe:
- name: nome limpo do produto
- quantity: número decimal; use 1 quando não houver quantidade
- unitPrice: use 0 quando não houver preço
- sectionName: seção provável do supermercado

Texto OCR:
"""
$rawText
"""
''';
  }

  static const _responseFormat = {
    'type': 'text',
    'mime_type': 'application/json',
    'schema': {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {
                'type': 'string',
                'description': 'Nome limpo do produto.',
              },
              'quantity': {
                'type': 'number',
                'description': 'Quantidade do produto. Use 1 se não houver.',
              },
              'unitPrice': {
                'type': 'number',
                'description': 'Preço unitário. Use 0 se não houver.',
              },
              'sectionName': {
                'type': 'string',
                'description': 'Seção provável do supermercado em português.',
              },
            },
            'required': ['name', 'quantity', 'unitPrice', 'sectionName'],
          },
        },
      },
      'required': ['items'],
    },
  };

  static String? _extractOutputText(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final outputText = payload['output_text'] ?? payload['outputText'];
      if (outputText is String) {
        return outputText;
      }

      final candidates = payload['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final text = _extractFirstText(candidates.first);
        if (text != null) {
          return text;
        }
      }

      final output = payload['output'];
      if (output != null) {
        return _extractFirstText(output);
      }

      final steps = payload['steps'];
      if (steps != null) {
        return _extractFirstText(steps);
      }
    }
    return null;
  }

  static List<dynamic>? _decodeItems(String value) {
    final trimmed = value.trim();
    final withoutFence = trimmed
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(withoutFence);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'] ?? decoded['produtos'] ?? decoded['itens'];
      if (items is List) {
        return items;
      }
      if (_readString(decoded['name'] ?? decoded['produto']).isNotEmpty) {
        return [decoded];
      }
    }
    return null;
  }

  static String? _extractFirstText(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is List) {
      for (final entry in value) {
        final text = _extractFirstText(entry);
        if (text != null) {
          return text;
        }
      }
    }
    if (value is Map) {
      for (final key in const ['text', 'output_text', 'outputText']) {
        final text = value[key];
        if (text is String) {
          return text;
        }
      }
      for (final key in const ['content', 'parts', 'message', 'delta']) {
        final text = _extractFirstText(value[key]);
        if (text != null) {
          return text;
        }
      }
    }
    return null;
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
            json['preçoUnitário'] ??
            json['preco'] ??
            json['preço'],
      ),
      sectionName: _readString(
        json['sectionName'] ??
            json['section'] ??
            json['secao'] ??
            json['seção'] ??
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
