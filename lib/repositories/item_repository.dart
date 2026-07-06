import '../models/shopping_item.dart';

abstract class ItemRepository {
  List<ShoppingItem> getAll();
  Future<void> save(ShoppingItem item);
  Future<void> delete(String id);
}
