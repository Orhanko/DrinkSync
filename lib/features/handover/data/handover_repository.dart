import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HandoverRepository {
  final FirebaseFirestore _fs;
  HandoverRepository({FirebaseFirestore? firestore}) : _fs = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _cafeDoc(String cafeId) => _fs.collection('cafes').doc(cafeId);

  CollectionReference<Map<String, dynamic>> _sessionsCol(String cafeId) =>
      _cafeDoc(cafeId).collection('handoverSessions');

  CollectionReference<Map<String, dynamic>> _drinksCol(String cafeId) => _cafeDoc(cafeId).collection('drinks');

  /// Returns cafe's currently open session id (global lock), or null.
  Stream<String?> watchActiveSessionId(String cafeId) {
    return _cafeDoc(cafeId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final v = data['openSessionId'];
      return v is String ? v : null;
    });
  }

  /// One-shot read of current open session id.
  Future<String?> getActiveSessionId({required String cafeId, required String uid}) async {
    final doc = await _cafeDoc(cafeId).get();
    final data = doc.data();
    if (data == null) return null;
    final v = data['openSessionId'];
    return v is String ? v : null;
  }

  // { drinkId: { name, price, qty } }  -- price u feningama
  Future<Map<String, dynamic>> _makeDrinksSnapshot(String cafeId) async {
    final snap = await _drinksCol(cafeId).get();
    final Map<String, dynamic> m = {};
    for (final d in snap.docs) {
      final data = d.data();
      m[d.id] = {
        'name': data['name'],
        'price': (data['price'] as num?)?.toInt() ?? 0,
        'qty': (data['quantity'] as num?)?.toInt() ?? 0,
      };
    }
    return m;
  }

  /// Compute settlement values on client (kept as-is with your structure)
  Map<String, dynamic> _computeSettlement({
    required Map<String, dynamic> openingSnapshot,
    required Map<String, dynamic> closingSnapshot,
    required Map<String, dynamic> restock,
    required int openingCashCents,
    required int cashCount,
    required int expenses,
  }) {
    // Sum value of sold items from qty delta * price (very simple example)
    int revenue = 0;
    closingSnapshot.forEach((id, c) {
      final openQty = (openingSnapshot[id]?['qty'] as num?)?.toInt() ?? 0;
      final closeQty = (c['qty'] as num?)?.toInt() ?? 0;
      final restocked = (restock[id] as num?)?.toInt() ?? 0;
      final price = (openingSnapshot[id]?['price'] as num?)?.toInt() ?? 0;
      // Items sold = open + restock - close
      final sold = (openQty + restocked) - closeQty;
      if (sold > 0) {
        revenue += sold * price;
      }
    });

    final lhs = openingCashCents + revenue - expenses;
    final rhs = cashCount;
    final deltaCents = rhs - lhs;

    return {
      'revenue': revenue,
      'lhs': lhs,
      'rhs': rhs,
      'deltaCents': deltaCents,
      'status': deltaCents == 0 ? 'balanced' : 'mismatch',
    };
  }

  /// START SESSION (atomic): ensure only one open per cafe
  Future<String> startSession({
    required String cafeId,
    required String openedBy,
    required String openedByName,
    required int openingCashCents,
    String? deviceId,
  }) async {
    final cafeRef = _cafeDoc(cafeId);
    final sessions = _sessionsCol(cafeId);
    // ✅ PRE-FLIGHT: provjeri da li postoji članstvo u /cafes/{cafeId}/members/{uid}
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final memberRef = _cafeDoc(cafeId).collection('members').doc(uid);
    final memberSnap = await memberRef.get();
    debugPrint("[handover] member exists for uid=$uid in cafeId=$cafeId -> ${memberSnap.exists}");

    final sessionId = await _fs.runTransaction<String>((tx) async {
      final cafeSnap = await tx.get(cafeRef);
      final cafe = cafeSnap.data() ?? <String, dynamic>{};

      // 👇 LOG: trenutno stanje locka na cafe dokumentu
      debugPrint("[handover] cafe.lock BEFORE open -> openSessionId=${cafe['openSessionId']}");

      if (cafe['openSessionId'] != null) {
        throw StateError('SHIFT_ALREADY_OPEN');
      }

      final sessionRef = sessions.doc();
      final now = FieldValue.serverTimestamp();

      // opening snapshot from current drinks
      final openingSnapshot = await _makeDrinksSnapshot(cafeId);
      final userName = await _getUserDisplayName(openedBy) ?? '';

      // 👇 Sastavimo payload da jasno vidimo šta pravila ocjenjuju
      final payload = <String, dynamic>{
        'status': 'open',
        'openedAt': now,
        'openedBy': openedBy,
        'openedByName': userName,
        'openingCashCents': openingCashCents, // int
        'openingSnapshot': openingSnapshot, // map
        if (deviceId != null) 'deviceId': deviceId, // opcionalno
        // Namjerno NE šaljemo 'restock' na create
      };

      // 👇 LOG: tačno šta šaljemo u create
      debugPrint("[handover] CREATE payload -> $payload");
      debugPrint("[handover] uid=${FirebaseAuth.instance.currentUser?.uid}");
      debugPrint("[handover] cafeId=$cafeId");

      tx.set(sessionRef, payload);

      tx.update(cafeRef, {'openSessionId': sessionRef.id, 'openSessionDeviceId': deviceId, 'openSessionOpenedAt': now});

      return sessionRef.id;
    });

    // 👇 LOG: novo otvoreni sessionId
    debugPrint("[handover] OPEN OK -> sessionId=$sessionId");
    return sessionId;
  }

  Future<String?> _getUserDisplayName(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snap.data()?['displayName'] as String?;
  }

  /// CLOSE SESSION (atomic): only the current open can close
  Future<void> closeSession({
    required String cafeId,
    required String sessionId,
    required String closedBy,
    required String closedByName,
    required int cashCount,
    required int expenses,
  }) async {
    final cafeRef = _cafeDoc(cafeId);
    final sessionRef = _sessionsCol(cafeId).doc(sessionId);

    await _fs.runTransaction((tx) async {
      final cafeSnap = await tx.get(cafeRef);
      final cafe = cafeSnap.data() ?? <String, dynamic>{};
      if (cafe['openSessionId'] != sessionId) {
        throw StateError('NOT_CURRENT_OPEN');
      }

      final now = FieldValue.serverTimestamp();
      // read opening data for settlement
      final sSnap = await tx.get(sessionRef);
      final sData = sSnap.data() ?? <String, dynamic>{};
      final Map<String, dynamic> openingSnapshot = Map<String, dynamic>.from(
        sData['openingSnapshot'] as Map? ?? const {},
      );
      final Map<String, dynamic> restock = Map<String, dynamic>.from(sData['restock'] as Map? ?? const {});
      final int openingCashCents = (sData['openingCashCents'] as num?)?.toInt() ?? 0;

      final closingSnapshot = await _makeDrinksSnapshot(cafeId);

      final settlement = _computeSettlement(
        openingSnapshot: openingSnapshot,
        closingSnapshot: closingSnapshot,
        restock: restock,
        openingCashCents: openingCashCents,
        cashCount: cashCount,
        expenses: expenses,
      );

      tx.update(sessionRef, {
        'status': 'closed',
        'closedAt': now,
        'closedBy': closedBy,
        'closedByName': closedByName,
        'closingSnapshot': closingSnapshot,
        'cashCount': cashCount,
        'expenses': expenses,
        'settlement': settlement,
        'computedDiff': (settlement['deltaCents'] as int?) ?? 0,
      });

      tx.update(cafeRef, {'openSessionId': null, 'openSessionDeviceId': null, 'openSessionOpenedAt': null});
    });
  }

  /// Increment restock counters inside session (merge, not required to be transactional)
  Future<void> incrementRestock({
    required String cafeId,
    required String sessionId,
    required String drinkId,
    int delta = 1,
  }) async {
    if (delta <= 0) return;
    await _sessionsCol(cafeId).doc(sessionId).set({
      'restock': {drinkId: FieldValue.increment(delta)},
    }, SetOptions(merge: true));
  }

  /// Bulk restock increment
  Future<void> incrementRestockBulk({
    required String cafeId,
    required String sessionId,
    required Map<String, int> deltas,
  }) async {
    if (deltas.isEmpty) return;
    final incMap = <String, dynamic>{};
    deltas.forEach((id, delta) {
      if (delta > 0) incMap[id] = FieldValue.increment(delta);
    });
    if (incMap.isEmpty) return;
    await _sessionsCol(cafeId).doc(sessionId).set({'restock': incMap}, SetOptions(merge: true));
  }
}
