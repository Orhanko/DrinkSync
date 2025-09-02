import 'package:cloud_firestore/cloud_firestore.dart';

class Shift {
  final String id;
  final String status; // OPEN | SUBMITTED | ACCEPTED
  final String openedByUid;
  final String openedByName;
  final DateTime openedAt;

  final Map<String, int> openingSnapshot; // drinkId -> qty
  final Map<String, int> pricesAtOpen; // drinkId -> price (int)

  // optional pri SUBMIT
  final Map<String, int>? closingSnapshot;
  final int? cashCounted;
  final int? expensesTotal;

  Shift({
    required this.id,
    required this.status,
    required this.openedByUid,
    required this.openedByName,
    required this.openedAt,
    required this.openingSnapshot,
    required this.pricesAtOpen,
    this.closingSnapshot,
    this.cashCounted,
    this.expensesTotal,
  });

  factory Shift.fromMap(String id, Map<String, dynamic> m) {
    Map<String, int> _mapInt(Map? raw) =>
        raw == null ? {} : raw.map((k, v) => MapEntry(k as String, (v as num).toInt()));
    return Shift(
      id: id,
      status: m['status'] as String,
      openedByUid: m['openedByUid'] as String,
      openedByName: m['openedByName'] as String? ?? '',
      openedAt: (m['openedAt'] as Timestamp).toDate(),
      openingSnapshot: _mapInt(m['openingSnapshot'] as Map?),
      pricesAtOpen: _mapInt(m['pricesAtOpen'] as Map?),
      closingSnapshot: m['closingSnapshot'] == null ? null : _mapInt(m['closingSnapshot'] as Map),
      cashCounted: m['cashCounted'] == null ? null : (m['cashCounted'] as num).toInt(),
      expensesTotal: m['expensesTotal'] == null ? null : (m['expensesTotal'] as num).toInt(),
    );
  }
}
