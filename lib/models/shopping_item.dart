class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.sectionId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.purchased,
  });

  final String id;
  final String listId;
  final String sectionId;
  final String name;
  final double quantity;
  final double unitPrice;
  final bool purchased;

  double get total => quantity * unitPrice;

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? sectionId,
    String? name,
    double? quantity,
    double? unitPrice,
    bool? purchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      purchased: purchased ?? this.purchased,
    );
  }
}
