import 'package:cloud_firestore/cloud_firestore.dart';

class HandoverSession {
  final String id;
  final String cafeId;
  final String status; // "open" | "closed"
  final String openedBy;
  final String openedByName;
  final DateTime openedAt;

  // nullable dok je "open"
  final String? closedBy;
  final String? closedByName;
  final DateTime? closedAt;

  // snapshots: { drinkId: { "qty": int, "name": String } }
  final Map<String, dynamic> openingSnapshot;
  final Map<String, dynamic>? closingSnapshot;

  // novac u feningima
  final int? cashCount;
  final int? expenses;
  final int? computedDiff; // cashCount - expenses - expectedRevenue

  HandoverSession({
    required this.id,
    required this.cafeId,
    required this.status,
    required this.openedBy,
    required this.openedByName,
    required this.openedAt,
    required this.openingSnapshot,
    this.closedBy,
    this.closedByName,
    this.closedAt,
    this.closingSnapshot,
    this.cashCount,
    this.expenses,
    this.computedDiff,
  });

  factory HandoverSession.fromDoc(String cafeId, String id, Map<String, dynamic> d) {
    return HandoverSession(
      id: id,
      cafeId: cafeId,
      status: d['status'] as String,
      openedBy: d['openedBy'] as String,
      openedByName: d['openedByName'] as String? ?? '',
      openedAt: (d['openedAt'] as Timestamp).toDate(),
      openingSnapshot: Map<String, dynamic>.from(d['openingSnapshot'] as Map),
      closedBy: d['closedBy'] as String?,
      closedByName: d['closedByName'] as String?,
      closedAt: (d['closedAt'] as Timestamp?)?.toDate(),
      closingSnapshot: d['closingSnapshot'] == null ? null : Map<String, dynamic>.from(d['closingSnapshot'] as Map),
      cashCount: d['cashCount'] as int?,
      expenses: d['expenses'] as int?,
      computedDiff: d['computedDiff'] as int?,
    );
  }
}
