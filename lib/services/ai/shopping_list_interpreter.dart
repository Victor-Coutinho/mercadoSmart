import '../../models/imported_shopping_item.dart';

abstract class ShoppingListInterpreter {
  Future<List<ImportedShoppingItem>> interpret(String rawText);
}
