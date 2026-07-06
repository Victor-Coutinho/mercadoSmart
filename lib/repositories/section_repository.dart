import '../models/shopping_section.dart';

abstract class SectionRepository {
  List<ShoppingSection> getAll();
  Future<void> save(ShoppingSection section);
  Future<void> delete(String id);
}
