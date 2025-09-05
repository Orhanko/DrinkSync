import 'package:cloud_firestore/cloud_firestore.dart';

class HandoverRepository {
  final FirebaseFirestore _fs;
  HandoverRepository({FirebaseFirestore? firestore}) : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('handoverSessions');

  CollectionReference<Map<String, dynamic>> _drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  // { drinkId: { name, price, qty } }  -- price u feningama
  Future<Map<String, dynamic>> _makeDrinksSnapshot(String cafeId) async {
    final snap = await _drinksCol(cafeId).get();
    final Map<String, dynamic> m = {};
    for (final d in snap.docs) {
      final data = d.data();
      m[d.id] = {
        'name': data['name'] ?? '',
        'price': (data['price'] as num?)?.toInt() ?? 0, // feninga
        'qty': (data['quantity'] as num?)?.toInt() ?? 0,
      };
    }
    return m;
  }

  Future<String?> getActiveSessionId({required String cafeId, required String uid}) async {
    final q = await _sessionsCol(
      cafeId,
    ).where('openedBy', isEqualTo: uid).where('status', isEqualTo: 'open').limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  Future<String> startSession({
    required String cafeId,
    required String uid,
    required String openedByName,
    required int openingCashCents, // 👈 NOVO
  }) async {
    final openingSnapshot = await _makeDrinksSnapshot(cafeId);
    final ref = _sessionsCol(cafeId).doc();

    await ref.set({
      'status': 'open',
      'openedAt': FieldValue.serverTimestamp(),
      'openedBy': uid,
      'openedByName': openedByName,
      'openingCashCents': openingCashCents, // 👈 NOVO
      'openingSnapshot': openingSnapshot,
      'restock': <String, int>{}, // map(drinkId->total delta) – prazno na startu
    });

    return ref.id;
  }

  // pomoćno – obračun na zatvaranju
  Map<String, dynamic> _computeSettlement({
    required Map<String, dynamic> openingSnapshot,
    required Map<String, dynamic> closingSnapshot,
    required Map<String, dynamic> restock,
    required int openingCashCents,
    required int cashCount,
    required int expenses,
  }) {
    int revenue = 0;

    for (final entry in openingSnapshot.entries) {
      final String id = entry.key;
      final Map<String, dynamic> open = (entry.value as Map<String, dynamic>);
      final int openQty = (open['qty'] as num?)?.toInt() ?? 0;
      final int price = (open['price'] as num?)?.toInt() ?? 0; // feninga

      final int restockQty = (restock[id] as num?)?.toInt() ?? 0;
      final Map<String, dynamic>? close = (closingSnapshot[id] as Map<String, dynamic>?);
      final int closeQty = (close?['qty'] as num?)?.toInt() ?? 0;

      final int sold = openQty + restockQty - closeQty;
      if (sold > 0 && price > 0) {
        revenue += sold * price;
      }
    }

    final int lhs = revenue - expenses; // artikli - rashod
    final int rhs = cashCount - openingCashCents; // kasa - zaduženje
    final int delta = rhs - lhs; // >0 manjak ; <0 višak

    final String status = (delta == 0) ? 'OK' : (delta > 0 ? 'VISAK' : 'MANJAK');

    return {'lhs': lhs, 'rhs': rhs, 'deltaCents': delta, 'status': status, 'revenue': revenue};
  }

  Future<void> closeSession({
    required String cafeId,
    required String sessionId,
    required String uid,
    required String closedByName,
    required int cashCount, // feninga
    required int expenses, // feninga
  }) async {
    final sessionRef = _sessionsCol(cafeId).doc(sessionId);

    // 1) pročitaj postojeću sesiju (openingSnapshot, openingCash, restock)
    final sessionSnap = await sessionRef.get();
    final data = sessionSnap.data()!;
    final Map<String, dynamic> openingSnapshot = Map<String, dynamic>.from(data['openingSnapshot'] as Map);
    final Map<String, dynamic> restock = Map<String, dynamic>.from((data['restock'] ?? const {}) as Map);
    final int openingCashCents = (data['openingCashCents'] as num?)?.toInt() ?? 0;

    // 2) napravi closing snapshot
    final closingSnapshot = await _makeDrinksSnapshot(cafeId);

    // 3) obračun
    final settlement = _computeSettlement(
      openingSnapshot: openingSnapshot,
      closingSnapshot: closingSnapshot,
      restock: restock,
      openingCashCents: openingCashCents,
      cashCount: cashCount,
      expenses: expenses,
    );

    // 4) upiši zatvaranje + settlement
    await sessionRef.update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': uid,
      'closedByName': closedByName,
      'closingSnapshot': closingSnapshot,
      'cashCount': cashCount,
      'expenses': expenses,
      'settlement': settlement,
    });
  }

  /// Pozovi ovo iz inventara (batch potvrde) za svaku **pozitivnu** promjenu.
  Future<void> incrementRestock({
    required String cafeId,
    required String sessionId,
    required String drinkId,
    required int delta, // >0
  }) async {
    await _sessionsCol(cafeId).doc(sessionId).set({
      'restock': {drinkId: FieldValue.increment(delta)},
    }, SetOptions(merge: true));
  }

  // HandoverRepository.dart

  Future<void> incrementRestockBulk({
    required String cafeId,
    required String sessionId,
    required Map<String, int> deltas, // drinkId -> delta (>0)
  }) async {
    if (deltas.isEmpty) return;

    // Složimo { drinkId: FieldValue.increment(delta) } pa merge u restock
    final incMap = <String, dynamic>{};
    deltas.forEach((id, delta) {
      if (delta > 0) {
        incMap[id] = FieldValue.increment(delta);
      }
    });
    if (incMap.isEmpty) return;

    await _sessionsCol(cafeId).doc(sessionId).set({'restock': incMap}, SetOptions(merge: true));
  }
}
