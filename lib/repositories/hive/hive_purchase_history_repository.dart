import 'package:hive/hive.dart';

import '../../database/hive_boxes.dart';
import '../../models/purchase_history.dart';
import '../purchase_history_repository.dart';

class HivePurchaseHistoryRepository implements PurchaseHistoryRepository {
  Box<PurchaseHistory> get _box =>
      Hive.box<PurchaseHistory>(HiveBoxes.purchaseHistories);

  @override
  List<PurchaseHistory> getAll() {
    final histories = _box.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return histories;
  }

  @override
  Future<void> save(PurchaseHistory history) => _box.put(history.id, history);

  @override
  Future<void> delete(String id) => _box.delete(id);
}
