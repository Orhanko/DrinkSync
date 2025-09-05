// drinks_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../handover/data/handover_repository.dart'; // 👈 import handover repoa
import '../domain/drink.dart';

class DrinksRepository {
  final FirebaseFirestore _fs;
  final HandoverRepository _handover; // 👈 NOVO

  DrinksRepository({FirebaseFirestore? firestore, HandoverRepository? handover})
    : _fs = firestore ?? FirebaseFirestore.instance,
      _handover = handover ?? HandoverRepository(); // 👈 default

  CollectionReference<Map<String, dynamic>> _drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  CollectionReference<Map<String, dynamic>> _logsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('logs');

  Stream<List<Drink>> streamDrinks(String cafeId) {
    return _drinksCol(cafeId).orderBy('name').snapshots().map((snap) => snap.docs.map(Drink.fromDoc).toList());
  }

  /// [deltas] = { drinkId: +2 / -1 / ... }
  Future<void> applyDeltas({
    required String cafeId,
    required Map<String, int> deltas,
    String? updatedByUid,
    String? updatedByName,
  }) async {
    if (deltas.isEmpty) return;

    final batch = _fs.batch();
    final now = FieldValue.serverTimestamp();

    // 1) batch update pića
    deltas.forEach((drinkId, delta) {
      if (delta == 0) return;
      final ref = _drinksCol(cafeId).doc(drinkId);
      batch.update(ref, {
        'quantity': FieldValue.increment(delta),
        'updatedAt': now,
        'updatedBy': updatedByUid,
        'updatedByName': updatedByName,
      });
    });

    await batch.commit();

    // 2) logovi (best-effort)
    try {
      final writes = deltas.entries.where((e) => e.value != 0).map((e) {
        return _logsCol(cafeId).add({
          'drinkId': e.key,
          'delta': e.value,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': updatedByUid,
          'updatedByName': updatedByName,
        });
      }).toList();
      await Future.wait(writes);
    } catch (_) {
      // ignoriši
    }

    // 3) RESTOCK → aktivna smjena: upiši samo POZITIVNE delte (dodana roba)
    try {
      if (updatedByUid == null) return; // ne znamo ko je — preskoči

      // pokupi samo > 0
      final positive = <String, int>{};
      for (final e in deltas.entries) {
        if (e.value > 0) {
          positive[e.key] = (positive[e.key] ?? 0) + e.value;
        }
      }
      if (positive.isEmpty) return;

      final sessionId = await _handover.getActiveSessionId(cafeId: cafeId, uid: updatedByUid);
      if (sessionId == null) return; // nema aktivne smjene — nema restock zapisa

      // bulk upis u restock mapu
      await _handover.incrementRestockBulk(cafeId: cafeId, sessionId: sessionId, deltas: positive);
    } catch (_) {
      // ne ruši inventar ako restock propadne
    }
  }
}
