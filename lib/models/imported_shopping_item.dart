class ImportedShoppingItem {
  const ImportedShoppingItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.sectionName,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final String sectionName;

  ImportedShoppingItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    String? sectionName,
  }) {
    return ImportedShoppingItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      sectionName: sectionName ?? this.sectionName,
    );
  }
}
