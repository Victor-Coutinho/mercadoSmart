import 'package:uuid/uuid.dart';

import '../core/constants/default_sections.dart';
import '../models/imported_shopping_item.dart';
import '../models/market.dart';
import '../models/purchase_history.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/shopping_section.dart';
import '../repositories/item_repository.dart';
import '../repositories/market_repository.dart';
import '../repositories/purchase_history_repository.dart';
import '../repositories/section_repository.dart';
import '../repositories/shopping_list_repository.dart';

class ShoppingService {
  ShoppingService({
    required MarketRepository marketRepository,
    required ShoppingListRepository listRepository,
    required SectionRepository sectionRepository,
    required ItemRepository itemRepository,
    required PurchaseHistoryRepository historyRepository,
  })  : _marketRepository = marketRepository,
        _listRepository = listRepository,
        _sectionRepository = sectionRepository,
        _itemRepository = itemRepository,
        _historyRepository = historyRepository;

  final MarketRepository _marketRepository;
  final ShoppingListRepository _listRepository;
  final SectionRepository _sectionRepository;
  final ItemRepository _itemRepository;
  final PurchaseHistoryRepository _historyRepository;
  final _uuid = const Uuid();

  AppStateSnapshot snapshot() {
    return AppStateSnapshot(
      markets: _marketRepository.getAll(),
      lists: _listRepository.getAll(),
      sections: _sectionRepository.getAll(),
      items: _itemRepository.getAll(),
      histories: _historyRepository.getAll(),
    );
  }

  Future<void> ensureSeedData() async {
    if (_marketRepository.getAll().isNotEmpty) {
      return;
    }
    for (final name in const [
      'Assaí',
      'Atacadão',
      'Carrefour',
      'Mercantil Rodrigues',
    ]) {
      await _marketRepository.save(Market(id: _uuid.v4(), name: name));
    }
  }

  Future<Market> createMarket(String name) async {
    final existing = _marketRepository
        .getAll()
        .where((market) => market.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      return existing;
    }

    final market = Market(id: _uuid.v4(), name: name.trim());
    await _marketRepository.save(market);
    return market;
  }

  Future<ShoppingList> createList({
    required String name,
    required String marketId,
    String? newMarketName,
  }) async {
    var resolvedMarketId = marketId;
    if ((newMarketName ?? '').trim().isNotEmpty) {
      final market = await createMarket(newMarketName!.trim());
      resolvedMarketId = market.id;
    }

    final list = ShoppingList(
      id: _uuid.v4(),
      name: name.trim(),
      marketId: resolvedMarketId,
      createdAt: DateTime.now(),
    );
    await _listRepository.save(list);

    for (var i = 0; i < DefaultSections.names.length; i++) {
      await _sectionRepository.save(
        ShoppingSection(
          id: _uuid.v4(),
          listId: list.id,
          name: DefaultSections.names[i],
          order: i,
        ),
      );
    }
    return list;
  }

  Future<void> renameList(String id, String name) async {
    final list = _listRepository.getAll().firstWhere((entry) => entry.id == id);
    await _listRepository.save(list.copyWith(name: name.trim()));
  }

  Future<ShoppingList> duplicateList(String id) async {
    final source =
        _listRepository.getAll().firstWhere((entry) => entry.id == id);
    final duplicated = source.copyWith(
      id: _uuid.v4(),
      name: '${source.name} cópia',
      createdAt: DateTime.now(),
    );
    await _listRepository.save(duplicated);

    final sectionIdMap = <String, String>{};
    final sourceSections = sectionsForList(id);
    for (final section in sourceSections) {
      final newSection = section.copyWith(
        id: _uuid.v4(),
        listId: duplicated.id,
      );
      sectionIdMap[section.id] = newSection.id;
      await _sectionRepository.save(newSection);
    }

    for (final item in itemsForList(id)) {
      await _itemRepository.save(
        item.copyWith(
          id: _uuid.v4(),
          listId: duplicated.id,
          sectionId: sectionIdMap[item.sectionId] ?? item.sectionId,
          purchased: false,
        ),
      );
    }
    return duplicated;
  }

  Future<PurchaseHistory> saveListToHistory({
    required String listId,
    required String historyName,
  }) async {
    final list =
        _listRepository.getAll().firstWhere((entry) => entry.id == listId);
    final market = _marketRepository
        .getAll()
        .firstWhere((entry) => entry.id == list.marketId);
    final sections = sectionsForList(listId);
    final items = itemsForList(listId);

    final sectionNames = {
      for (final section in sections) section.id: section.name,
    };
    final history = PurchaseHistory(
      id: _uuid.v4(),
      name: historyName.trim(),
      marketId: market.id,
      marketName: market.name,
      savedAt: DateTime.now(),
      total: items.fold<double>(0, (sum, item) => sum + item.total),
      sections: sections
          .map(
            (section) => PurchaseHistorySection(
              snapshotId: section.id,
              name: section.name,
              order: section.order,
            ),
          )
          .toList(),
      items: items
          .map(
            (item) => PurchaseHistoryItem(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              sectionSnapshotId: item.sectionId,
              sectionName: sectionNames[item.sectionId] ?? 'Sem seção',
            ),
          )
          .toList(),
    );

    await _historyRepository.save(history);
    return history;
  }

  Future<ShoppingList> reuseHistory({
    required String historyId,
    required String listName,
  }) async {
    final history = _historyRepository
        .getAll()
        .firstWhere((entry) => entry.id == historyId);
    final list = ShoppingList(
      id: _uuid.v4(),
      name: listName.trim(),
      marketId: history.marketId,
      createdAt: DateTime.now(),
    );
    await _listRepository.save(list);

    final sectionIdMap = <String, String>{};
    final sortedSections = [...history.sections]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final section in sortedSections) {
      final newSection = ShoppingSection(
        id: _uuid.v4(),
        listId: list.id,
        name: section.name,
        order: section.order,
      );
      sectionIdMap[section.snapshotId] = newSection.id;
      await _sectionRepository.save(newSection);
    }

    if (sectionIdMap.isEmpty) {
      final fallbackSection = ShoppingSection(
        id: _uuid.v4(),
        listId: list.id,
        name: 'Geral',
        order: 0,
      );
      sectionIdMap['fallback'] = fallbackSection.id;
      await _sectionRepository.save(fallbackSection);
    }

    for (final item in history.items) {
      await _itemRepository.save(
        ShoppingItem(
          id: _uuid.v4(),
          listId: list.id,
          sectionId:
              sectionIdMap[item.sectionSnapshotId] ?? sectionIdMap.values.first,
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          purchased: false,
        ),
      );
    }
    return list;
  }

  Future<void> deleteLists(Iterable<String> ids) async {
    for (final id in ids) {
      for (final item in itemsForList(id)) {
        await _itemRepository.delete(item.id);
      }
      for (final section in sectionsForList(id)) {
        await _sectionRepository.delete(section.id);
      }
      await _listRepository.delete(id);
    }
  }

  List<ShoppingSection> sectionsForList(String listId) {
    final sections = _sectionRepository
        .getAll()
        .where((section) => section.listId == listId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return sections;
  }

  List<ShoppingItem> itemsForList(String listId) {
    final items = _itemRepository
        .getAll()
        .where((item) => item.listId == listId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<void> addItem({
    required String listId,
    required String sectionId,
    required String name,
    required double quantity,
    required double unitPrice,
  }) async {
    await _itemRepository.save(
      ShoppingItem(
        id: _uuid.v4(),
        listId: listId,
        sectionId: sectionId,
        name: name.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
        purchased: false,
      ),
    );
  }

  Future<void> importItems({
    required String listId,
    required List<ImportedShoppingItem> importedItems,
  }) async {
    if (importedItems.isEmpty) return;

    final sectionsByName = {
      for (final section in sectionsForList(listId))
        _normalize(section.name): section,
    };

    for (final item in importedItems) {
      final name = item.name.trim();
      if (name.isEmpty) continue;

      final sectionKey = _normalize(item.sectionName);
      var section = sectionsByName[sectionKey];
      if (section == null) {
        section = ShoppingSection(
          id: _uuid.v4(),
          listId: listId,
          name: item.sectionName.trim().isEmpty
              ? 'Mercearia'
              : item.sectionName.trim(),
          order: sectionsByName.length,
        );
        await _sectionRepository.save(section);
        sectionsByName[sectionKey] = section;
      }

      await _itemRepository.save(
        ShoppingItem(
          id: _uuid.v4(),
          listId: listId,
          sectionId: section.id,
          name: name,
          quantity: item.quantity <= 0 ? 1 : item.quantity,
          unitPrice: item.unitPrice < 0 ? 0 : item.unitPrice,
          purchased: false,
        ),
      );
    }
  }

  Future<void> updateItem(ShoppingItem item) => _itemRepository.save(item);

  Future<void> deleteItem(String id) => _itemRepository.delete(id);

  Future<void> togglePurchased(ShoppingItem item) {
    return _itemRepository.save(item.copyWith(purchased: !item.purchased));
  }

  Future<void> addSection(String listId, String name) async {
    final nextOrder = sectionsForList(listId).length;
    await _sectionRepository.save(
      ShoppingSection(
        id: _uuid.v4(),
        listId: listId,
        name: name.trim(),
        order: nextOrder,
      ),
    );
  }

  Future<void> renameSection(String id, String name) async {
    final section =
        _sectionRepository.getAll().firstWhere((entry) => entry.id == id);
    await _sectionRepository.save(section.copyWith(name: name.trim()));
  }

  Future<void> deleteSection(ShoppingSection section) async {
    for (final item in _itemRepository
        .getAll()
        .where((item) => item.sectionId == section.id)) {
      await _itemRepository.delete(item.id);
    }
    await _sectionRepository.delete(section.id);
    await _normalizeSectionOrder(section.listId);
  }

  Future<void> moveSection(ShoppingSection section, int delta) async {
    final sections = sectionsForList(section.listId);
    final currentIndex = sections.indexWhere((entry) => entry.id == section.id);
    final targetIndex = currentIndex + delta;
    if (currentIndex < 0 || targetIndex < 0 || targetIndex >= sections.length) {
      return;
    }

    final moved = sections.removeAt(currentIndex);
    sections.insert(targetIndex, moved);
    for (var i = 0; i < sections.length; i++) {
      await _sectionRepository.save(sections[i].copyWith(order: i));
    }
  }

  Future<void> reorderSection(String listId, int oldIndex, int newIndex) async {
    final sections = sectionsForList(listId);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = sections.removeAt(oldIndex);
    sections.insert(newIndex, moved);
    for (var i = 0; i < sections.length; i++) {
      await _sectionRepository.save(sections[i].copyWith(order: i));
    }
  }

  Future<void> _normalizeSectionOrder(String listId) async {
    final sections = sectionsForList(listId);
    for (var i = 0; i < sections.length; i++) {
      await _sectionRepository.save(sections[i].copyWith(order: i));
    }
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
}

class AppStateSnapshot {
  const AppStateSnapshot({
    required this.markets,
    required this.lists,
    required this.sections,
    required this.items,
    required this.histories,
  });

  final List<Market> markets;
  final List<ShoppingList> lists;
  final List<ShoppingSection> sections;
  final List<ShoppingItem> items;
  final List<PurchaseHistory> histories;
}
