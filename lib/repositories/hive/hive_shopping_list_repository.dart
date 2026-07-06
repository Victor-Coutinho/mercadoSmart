import 'package:hive/hive.dart';

import '../../database/hive_boxes.dart';
import '../../models/shopping_list.dart';
import '../shopping_list_repository.dart';

class HiveShoppingListRepository implements ShoppingListRepository {
  Box<ShoppingList> get _box => Hive.box<ShoppingList>(HiveBoxes.shoppingLists);

  @override
  List<ShoppingList> getAll() {
    final lists = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  @override
  Future<void> save(ShoppingList list) => _box.put(list.id, list);

  @override
  Future<void> delete(String id) => _box.delete(id);
}
