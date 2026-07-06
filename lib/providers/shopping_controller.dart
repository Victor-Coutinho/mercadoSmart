import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/shopping_section.dart';
import '../repositories/hive/hive_item_repository.dart';
import '../repositories/hive/hive_market_repository.dart';
import '../repositories/hive/hive_purchase_history_repository.dart';
import '../repositories/hive/hive_section_repository.dart';
import '../repositories/hive/hive_shopping_list_repository.dart';
import '../services/shopping_service.dart';
import 'app_state.dart';

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService(
    marketRepository: HiveMarketRepository(),
    listRepository: HiveShoppingListRepository(),
    sectionRepository: HiveSectionRepository(),
    itemRepository: HiveItemRepository(),
    historyRepository: HivePurchaseHistoryRepository(),
  );
});

final shoppingControllerProvider =
    NotifierProvider<ShoppingController, AppState>(ShoppingController.new);

class ShoppingController extends Notifier<AppState> {
  late final ShoppingService _service = ref.read(shoppingServiceProvider);

  @override
  AppState build() {
    final snapshot = _service.snapshot();
    if (snapshot.markets.isEmpty) {
      Future.microtask(() async {
        await _service.ensureSeedData();
        _refresh();
      });
    }
    return AppState.fromSnapshot(snapshot);
  }

  Future<void> createMarket(String name) async {
    await _service.createMarket(name);
    _refresh();
  }

  Future<ShoppingList> createList({
    required String name,
    required String marketId,
    String? newMarketName,
  }) async {
    final list = await _service.createList(
      name: name,
      marketId: marketId,
      newMarketName: newMarketName,
    );
    _refresh();
    return list;
  }

  Future<void> renameList(String id, String name) async {
    await _service.renameList(id, name);
    _refresh();
  }

  Future<ShoppingList> duplicateList(String id) async {
    final list = await _service.duplicateList(id);
    _refresh();
    return list;
  }

  Future<void> saveListToHistory({
    required String listId,
    required String historyName,
  }) async {
    await _service.saveListToHistory(
      listId: listId,
      historyName: historyName,
    );
    _refresh();
  }

  Future<ShoppingList> reuseHistory({
    required String historyId,
    required String listName,
  }) async {
    final list = await _service.reuseHistory(
      historyId: historyId,
      listName: listName,
    );
    _refresh();
    return list;
  }

  Future<void> deleteLists(Iterable<String> ids) async {
    await _service.deleteLists(ids);
    _refresh();
  }

  Future<void> addItem({
    required String listId,
    required String sectionId,
    required String name,
    required double quantity,
    required double unitPrice,
  }) async {
    await _service.addItem(
      listId: listId,
      sectionId: sectionId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
    );
    _refresh();
  }

  Future<void> updateItem(ShoppingItem item) async {
    await _service.updateItem(item);
    _refresh();
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    _refresh();
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    await _service.togglePurchased(item);
    _refresh();
  }

  Future<void> addSection(String listId, String name) async {
    await _service.addSection(listId, name);
    _refresh();
  }

  Future<void> renameSection(String id, String name) async {
    await _service.renameSection(id, name);
    _refresh();
  }

  Future<void> deleteSection(ShoppingSection section) async {
    await _service.deleteSection(section);
    _refresh();
  }

  Future<void> moveSection(ShoppingSection section, int delta) async {
    await _service.moveSection(section, delta);
    _refresh();
  }

  Future<void> reorderSection(String listId, int oldIndex, int newIndex) async {
    await _service.reorderSection(listId, oldIndex, newIndex);
    _refresh();
  }

  void _refresh() {
    state = AppState.fromSnapshot(_service.snapshot());
  }
}
