import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/drink.dart';

class DrinksRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  Stream<List<Drink>> streamDrinks(String cafeId) {
    return drinksCol(
      cafeId,
    ).orderBy('name').snapshots().map((qs) => qs.docs.map((d) => Drink.fromFirestore(d.id, d.data())).toList());
  }

  Future<void> applyDeltas({
    required String cafeId,
    required Map<String, int> deltas, // drinkId -> delta
    required String? updatedByUid,
    required String? updatedByName,
  }) async {
    if (deltas.isEmpty) return;
    final batch = _fs.batch();
    final col = drinksCol(cafeId);
    final ts = FieldValue.serverTimestamp();
    deltas.forEach((id, delta) {
      batch.update(col.doc(id), {
        'quantity': FieldValue.increment(delta),
        'updatedAt': ts,
        'updatedBy': updatedByUid,
        'updatedByName': updatedByName,
      });
    });
    await batch.commit();
  }
}
