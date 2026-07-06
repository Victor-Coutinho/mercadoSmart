import 'package:hive/hive.dart';

import '../../models/market.dart';
import '../../models/purchase_history.dart';
import '../../models/shopping_item.dart';
import '../../models/shopping_list.dart';
import '../../models/shopping_section.dart';

class AppAdapters {
  static void register() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MarketAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShoppingSectionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PurchaseHistoryAdapter());
    }
  }
}

class MarketAdapter extends TypeAdapter<Market> {
  @override
  final int typeId = 1;

  @override
  Market read(BinaryReader reader) {
    return Market(id: reader.readString(), name: reader.readString());
  }

  @override
  void write(BinaryWriter writer, Market obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name);
  }
}

class ShoppingListAdapter extends TypeAdapter<ShoppingList> {
  @override
  final int typeId = 2;

  @override
  ShoppingList read(BinaryReader reader) {
    return ShoppingList(
      id: reader.readString(),
      name: reader.readString(),
      marketId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingList obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.marketId)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

class ShoppingSectionAdapter extends TypeAdapter<ShoppingSection> {
  @override
  final int typeId = 3;

  @override
  ShoppingSection read(BinaryReader reader) {
    return ShoppingSection(
      id: reader.readString(),
      listId: reader.readString(),
      name: reader.readString(),
      order: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingSection obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.listId)
      ..writeString(obj.name)
      ..writeInt(obj.order);
  }
}

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 4;

  @override
  ShoppingItem read(BinaryReader reader) {
    return ShoppingItem(
      id: reader.readString(),
      listId: reader.readString(),
      sectionId: reader.readString(),
      name: reader.readString(),
      quantity: reader.readDouble(),
      unitPrice: reader.readDouble(),
      purchased: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.listId)
      ..writeString(obj.sectionId)
      ..writeString(obj.name)
      ..writeDouble(obj.quantity)
      ..writeDouble(obj.unitPrice)
      ..writeBool(obj.purchased);
  }
}

class PurchaseHistoryAdapter extends TypeAdapter<PurchaseHistory> {
  @override
  final int typeId = 5;

  @override
  PurchaseHistory read(BinaryReader reader) {
    final sectionsLength = reader.readInt();
    final sections = <PurchaseHistorySection>[];
    for (var i = 0; i < sectionsLength; i++) {
      sections.add(
        PurchaseHistorySection(
          snapshotId: reader.readString(),
          name: reader.readString(),
          order: reader.readInt(),
        ),
      );
    }

    final itemsLength = reader.readInt();
    final items = <PurchaseHistoryItem>[];
    for (var i = 0; i < itemsLength; i++) {
      items.add(
        PurchaseHistoryItem(
          name: reader.readString(),
          quantity: reader.readDouble(),
          unitPrice: reader.readDouble(),
          sectionSnapshotId: reader.readString(),
          sectionName: reader.readString(),
        ),
      );
    }

    return PurchaseHistory(
      id: reader.readString(),
      name: reader.readString(),
      marketId: reader.readString(),
      marketName: reader.readString(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      total: reader.readDouble(),
      sections: sections,
      items: items,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseHistory obj) {
    writer.writeInt(obj.sections.length);
    for (final section in obj.sections) {
      writer
        ..writeString(section.snapshotId)
        ..writeString(section.name)
        ..writeInt(section.order);
    }

    writer.writeInt(obj.items.length);
    for (final item in obj.items) {
      writer
        ..writeString(item.name)
        ..writeDouble(item.quantity)
        ..writeDouble(item.unitPrice)
        ..writeString(item.sectionSnapshotId)
        ..writeString(item.sectionName);
    }

    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.marketId)
      ..writeString(obj.marketName)
      ..writeInt(obj.savedAt.millisecondsSinceEpoch)
      ..writeDouble(obj.total);
  }
}
