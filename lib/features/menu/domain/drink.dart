import 'package:cloud_firestore/cloud_firestore.dart';

class Drink {
  final String id;
  final String name;
  final int quantity;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;

  const Drink({
    required this.id,
    required this.name,
    required this.quantity,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  factory Drink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['updatedAt'];
    return Drink(
      id: doc.id,
      name: (data['name'] as String?) ?? 'N/A',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
      updatedBy: data['updatedBy'] as String?,
      updatedByName: data['updatedByName'] as String?,
    );
  }

  Drink copyWith({
    String? id,
    String? name,
    int? quantity,
    DateTime? updatedAt,
    String? updatedBy,
    String? updatedByName,
  }) {
    return Drink(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }
}
