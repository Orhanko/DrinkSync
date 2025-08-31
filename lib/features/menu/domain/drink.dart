class Drink {
  final String id;
  final String name;
  final int quantity;
  final String? updatedByName;
  final DateTime? updatedAt;

  Drink({required this.id, required this.name, required this.quantity, this.updatedByName, this.updatedAt});

  factory Drink.fromFirestore(String id, Map<String, dynamic> data) {
    return Drink(
      id: id,
      name: (data['name'] as String?) ?? 'N/A',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      updatedByName: data['updatedByName'] as String?,
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }
}
