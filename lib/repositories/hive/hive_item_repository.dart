import 'package:hive/hive.dart';

import '../../database/hive_boxes.dart';
import '../../models/shopping_item.dart';
import '../item_repository.dart';

class HiveItemRepository implements ItemRepository {
  Box<ShoppingItem> get _box => Hive.box<ShoppingItem>(HiveBoxes.items);

  @override
  List<ShoppingItem> getAll() => _box.values.toList();

  @override
  Future<void> save(ShoppingItem item) => _box.put(item.id, item);

  @override
  Future<void> delete(String id) => _box.delete(id);
}
