class ShoppingSection {
  const ShoppingSection({
    required this.id,
    required this.listId,
    required this.name,
    required this.order,
  });

  final String id;
  final String listId;
  final String name;
  final int order;

  ShoppingSection copyWith({
    String? id,
    String? listId,
    String? name,
    int? order,
  }) {
    return ShoppingSection(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }
}
