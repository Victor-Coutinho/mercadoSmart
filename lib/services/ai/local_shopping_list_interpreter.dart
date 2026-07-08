import '../../models/imported_shopping_item.dart';
import 'shopping_list_interpreter.dart';

class LocalShoppingListInterpreter implements ShoppingListInterpreter {
  static final _quantityAtStart = RegExp(
    r'^(\d+(?:[,.]\d+)?)\s*(kg|g|l|ml|un|und|x)?\s+(.+)$',
    caseSensitive: false,
  );
  static final _quantityAtEnd = RegExp(
    r'^(.+?)\s+(\d+(?:[,.]\d+)?)\s*(kg|g|l|ml|un|und|x)$',
    caseSensitive: false,
  );

  @override
  Future<List<ImportedShoppingItem>> interpret(String rawText) async {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_cleanLine)
        .where((line) => line.length >= 2)
        .where((line) => !_looksLikeHeader(line))
        .toList();

    final items = <ImportedShoppingItem>[];
    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed.name.length < 2) continue;
      items.add(parsed);
    }
    return items;
  }

  ImportedShoppingItem _parseLine(String line) {
    var quantity = 1.0;
    var name = line;

    final startMatch = _quantityAtStart.firstMatch(line);
    final endMatch = _quantityAtEnd.firstMatch(line);

    if (startMatch != null) {
      quantity = _parseQuantity(startMatch.group(1));
      name = startMatch.group(3) ?? line;
    } else if (endMatch != null) {
      name = endMatch.group(1) ?? line;
      quantity = _parseQuantity(endMatch.group(2));
    }

    name = _cleanProductName(name);
    return ImportedShoppingItem(
      name: _capitalize(name),
      quantity: quantity <= 0 ? 1 : quantity,
      unitPrice: 0,
      sectionName: _classifySection(name),
    );
  }

  static String _cleanLine(String value) {
    return value
        .replaceAll(RegExp(r'^[\-\*\u2022\[\]\(\)\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanProductName(String value) {
    return value
        .replaceAll(RegExp(r'[,;:.]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikeHeader(String line) {
    final normalized = _normalize(line);
    return normalized == 'lista' ||
        normalized == 'lista de compras' ||
        normalized == 'compras' ||
        normalized.contains('mercado') ||
        normalized.contains('supermercado');
  }

  static double _parseQuantity(String? value) {
    if (value == null) return 1;
    return double.tryParse(value.replaceAll(',', '.')) ?? 1;
  }

  static String _classifySection(String name) {
    final value = _normalize(name);

    if (_containsAny(value, [
      'banana',
      'maca',
      'laranja',
      'tomate',
      'alface',
      'cebola',
      'batata',
      'cenoura',
      'fruta',
      'legume',
      'verdura',
    ])) {
      return 'Hortifruti';
    }
    if (_containsAny(value, [
      'carne',
      'frango',
      'bife',
      'costela',
      'linguica',
      'peixe',
      'acougue',
      'moida',
    ])) {
      return 'Açougue';
    }
    if (_containsAny(value, ['pao', 'bolo', 'baguete', 'brioche'])) {
      return 'Padaria';
    }
    if (_containsAny(value, ['queijo', 'presunto', 'mortadela', 'salame'])) {
      return 'Frios';
    }
    if (_containsAny(value, [
      'detergente',
      'sabao',
      'amaciante',
      'desinfetante',
      'alcool',
      'limpeza',
      'agua sanitaria',
    ])) {
      return 'Limpeza';
    }
    if (_containsAny(value, [
      'shampoo',
      'condicionador',
      'sabonete',
      'pasta',
      'escova',
      'desodorante',
      'higiene',
    ])) {
      return 'Higiene';
    }
    if (_containsAny(value, [
      'agua',
      'suco',
      'refrigerante',
      'cerveja',
      'vinho',
      'bebida',
      'coca',
    ])) {
      return 'Bebidas';
    }
    if (_containsAny(value, ['pizza', 'lasanha', 'congelado', 'sorvete'])) {
      return 'Congelados';
    }
    return 'Mercearia';
  }

  static bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .trim();
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
