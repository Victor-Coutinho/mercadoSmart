class PurchaseHistory {
  const PurchaseHistory({
    required this.id,
    required this.name,
    required this.marketId,
    required this.marketName,
    required this.savedAt,
    required this.total,
    required this.sections,
    required this.items,
  });

  final String id;
  final String name;
  final String marketId;
  final String marketName;
  final DateTime savedAt;
  final double total;
  final List<PurchaseHistorySection> sections;
  final List<PurchaseHistoryItem> items;
}

class PurchaseHistorySection {
  const PurchaseHistorySection({
    required this.snapshotId,
    required this.name,
    required this.order,
  });

  final String snapshotId;
  final String name;
  final int order;
}

class PurchaseHistoryItem {
  const PurchaseHistoryItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.sectionSnapshotId,
    required this.sectionName,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final String sectionSnapshotId;
  final String sectionName;

  double get total => quantity * unitPrice;
}
