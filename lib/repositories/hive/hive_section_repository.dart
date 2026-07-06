import 'package:hive/hive.dart';

import '../../database/hive_boxes.dart';
import '../../models/shopping_section.dart';
import '../section_repository.dart';

class HiveSectionRepository implements SectionRepository {
  Box<ShoppingSection> get _box =>
      Hive.box<ShoppingSection>(HiveBoxes.sections);

  @override
  List<ShoppingSection> getAll() => _box.values.toList();

  @override
  Future<void> save(ShoppingSection section) => _box.put(section.id, section);

  @override
  Future<void> delete(String id) => _box.delete(id);
}
