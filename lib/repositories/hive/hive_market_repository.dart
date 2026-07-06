import 'package:hive/hive.dart';

import '../../database/hive_boxes.dart';
import '../../models/market.dart';
import '../market_repository.dart';

class HiveMarketRepository implements MarketRepository {
  Box<Market> get _box => Hive.box<Market>(HiveBoxes.markets);

  @override
  List<Market> getAll() {
    final markets = _box.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return markets;
  }

  @override
  Future<void> save(Market market) => _box.put(market.id, market);

  @override
  Future<void> delete(String id) => _box.delete(id);
}
