import '../models/shopping_list.dart';

abstract class ShoppingListRepository {
  List<ShoppingList> getAll();
  Future<void> save(ShoppingList list);
  Future<void> delete(String id);
}
