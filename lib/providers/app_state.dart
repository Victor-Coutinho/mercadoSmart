import '../models/market.dart';
import '../models/purchase_history.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/shopping_section.dart';
import '../services/shopping_service.dart';

class AppState {
  const AppState({
    required this.markets,
    required this.lists,
    required this.sections,
    required this.items,
    required this.histories,
  });

  factory AppState.fromSnapshot(AppStateSnapshot snapshot) {
    return AppState(
      markets: snapshot.markets,
      lists: snapshot.lists,
      sections: snapshot.sections,
      items: snapshot.items,
      histories: snapshot.histories,
    );
  }

  final List<Market> markets;
  final List<ShoppingList> lists;
  final List<ShoppingSection> sections;
  final List<ShoppingItem> items;
  final List<PurchaseHistory> histories;

  Market? marketById(String id) {
    for (final market in markets) {
      if (market.id == id) {
        return market;
      }
    }
    return null;
  }

  ShoppingList? listById(String id) {
    for (final list in lists) {
      if (list.id == id) {
        return list;
      }
    }
    return null;
  }

  List<ShoppingSection> sectionsForList(String listId) {
    final result = sections
        .where((section) => section.listId == listId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  List<ShoppingItem> itemsForList(String listId) {
    return items.where((item) => item.listId == listId).toList();
  }

  List<ShoppingItem> itemsForSection(String listId, String sectionId) {
    final result = items
        .where((item) => item.listId == listId && item.sectionId == sectionId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  ShoppingListSummary summaryFor(String listId) {
    final listItems = itemsForList(listId);
    return ShoppingListSummary(
      itemCount: listItems.length,
      purchasedCount: listItems.where((item) => item.purchased).length,
      total: listItems.fold<double>(0, (sum, item) => sum + item.total),
      purchasedTotal: listItems
          .where((item) => item.purchased)
          .fold<double>(0, (sum, item) => sum + item.total),
    );
  }

  List<PurchaseHistory> historiesForMarket(String marketId) {
    return histories.where((history) => history.marketId == marketId).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }
}

class ShoppingListSummary {
  const ShoppingListSummary({
    required this.itemCount,
    required this.purchasedCount,
    required this.total,
    required this.purchasedTotal,
  });

  final int itemCount;
  final int purchasedCount;
  final double total;
  final double purchasedTotal;
}
