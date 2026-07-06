import '../models/market.dart';

abstract class MarketRepository {
  List<Market> getAll();
  Future<void> save(Market market);
  Future<void> delete(String id);
}
