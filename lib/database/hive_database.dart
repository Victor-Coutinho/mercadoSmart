import 'package:hive_flutter/hive_flutter.dart';

import '../models/market.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/shopping_section.dart';
import '../models/purchase_history.dart';
import 'adapters/app_adapters.dart';
import 'hive_boxes.dart';

class HiveDatabase {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    AppAdapters.register();

    await Future.wait([
      Hive.openBox<Market>(HiveBoxes.markets),
      Hive.openBox<ShoppingList>(HiveBoxes.shoppingLists),
      Hive.openBox<ShoppingSection>(HiveBoxes.sections),
      Hive.openBox<ShoppingItem>(HiveBoxes.items),
      Hive.openBox<PurchaseHistory>(HiveBoxes.purchaseHistories),
    ]);
  }
}
