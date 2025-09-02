import 'package:cloud_firestore/cloud_firestore.dart';

class HandoverRepository {
  final FirebaseFirestore _fs;
  HandoverRepository({FirebaseFirestore? firestore}) : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('handoverSessions');

  CollectionReference<Map<String, dynamic>> _drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  /// Pomoćna: pročitaj sve artikle i vrati mapu:
  /// { drinkId: { name, priceCents, qty } }
  Future<Map<String, dynamic>> _makeDrinksSnapshot(String cafeId) async {
    final snap = await _drinksCol(cafeId).get();
    final Map<String, dynamic> m = {};
    for (final d in snap.docs) {
      final data = d.data();
      m[d.id] = {
        'name': data['name'] ?? '',
        'priceCents': (data['priceCents'] as num?)?.toInt() ?? 0,
        'qty': (data['quantity'] as num?)?.toInt() ?? 0,
      };
    }
    return m;
  }

  /// Vrati ID aktivne sesije za (cafeId, uid), ili null.
  /// ✅ Pravila i dokumenti koriste polje "openedBy" (ne "openedByUid").
  Future<String?> getActiveSessionId({required String cafeId, required String uid}) async {
    final q = await _sessionsCol(
      cafeId,
    ).where('openedBy', isEqualTo: uid).where('status', isEqualTo: 'open').limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  /// Kreira otvorenu smjenu sa snimkom stanja artikala (openingSnapshot). Vraća sessionId.
  /// ✅ Pišemo isključivo polja dozvoljena pravilima za create.
  Future<String> startSession({required String cafeId, required String uid, required String openedByName}) async {
    final openingSnapshot = await _makeDrinksSnapshot(cafeId);
    final ref = _sessionsCol(cafeId).doc();

    await ref.set({
      'status': 'open',
      'openedAt': FieldValue.serverTimestamp(),
      'openedBy': uid,
      'openedByName': openedByName,
      'openingSnapshot': openingSnapshot, // mora biti MAP (može i {}), ne null
    });

    return ref.id;
  }

  /// Zatvori smjenu: snimi closingSnapshot + gotovina/rashodi + computedDiff.
  /// ✅ Koristimo točna imena polja iz pravila za update.
  Future<void> closeSession({
    required String cafeId,
    required String sessionId,
    required String uid,
    required String closedByName,
    required int cashCount, // u centima
    required int expenses, // u centima
    int computedDiff = 0,
  }) async {
    final closingSnapshot = await _makeDrinksSnapshot(cafeId);

    final ref = _sessionsCol(cafeId).doc(sessionId);
    await ref.update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': uid,
      'closedByName': closedByName,
      'closingSnapshot': closingSnapshot,
      'cashCount': cashCount,
      'expenses': expenses,
      'computedDiff': computedDiff,
    });
  }
}
