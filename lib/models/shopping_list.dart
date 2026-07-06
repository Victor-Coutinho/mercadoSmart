class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.marketId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String marketId;
  final DateTime createdAt;

  ShoppingList copyWith({
    String? id,
    String? name,
    String? marketId,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      marketId: marketId ?? this.marketId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
