import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/drink.dart';

class DrinksRepository {
  final FirebaseFirestore _fs;
  DrinksRepository({FirebaseFirestore? firestore}) : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  CollectionReference<Map<String, dynamic>> _logsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('logs');

  /// Realtime stream liste pića
  Stream<List<Drink>> streamDrinks(String cafeId) {
    return _drinksCol(cafeId).orderBy('name').snapshots().map((snap) => snap.docs.map(Drink.fromDoc).toList());
  }

  /// Primjena delta promjena i (pokušaj) upisa logova.
  ///
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

    // 2) logovi (odvojeno od batch-a – ako padnu, ne rušimo glavni update)
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
      // namjerno ignorišemo – update je već uspješno primijenjen
    }
  }
}
