import '../models/purchase_history.dart';

abstract class PurchaseHistoryRepository {
  List<PurchaseHistory> getAll();
  Future<void> save(PurchaseHistory history);
  Future<void> delete(String id);
}
