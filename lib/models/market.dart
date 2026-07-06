class Market {
  const Market({required this.id, required this.name});

  final String id;
  final String name;

  Market copyWith({String? id, String? name}) {
    return Market(id: id ?? this.id, name: name ?? this.name);
  }
}
