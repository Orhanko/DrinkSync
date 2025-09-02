import 'package:cloud_firestore/cloud_firestore.dart';
import '../../menu/domain/drink.dart'; // koristi tvoj postojeći Drink model
import '../domain/shift.dart';

class ShiftsRepository {
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> cafes(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('shifts');

  CollectionReference<Map<String, dynamic>> drinksCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('drinks');

  CollectionReference<Map<String, dynamic>> logsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('logs');

  Stream<Shift?> streamActiveShift(String cafeId, String uid) {
    return cafes(cafeId)
        .where('status', isEqualTo: 'OPEN')
        .where('openedByUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((qs) => qs.docs.isEmpty ? null : Shift.fromMap(qs.docs.first.id, qs.docs.first.data()));
  }

  Future<List<Drink>> fetchAllDrinks(String cafeId) async {
    final qs = await drinksCol(cafeId).orderBy('name').get();
    return qs.docs.map((d) => Drink.fromDoc(d)).toList();
  }

  Future<void> openShift({required String cafeId, required String openedByUid, required String openedByName}) async {
    // snapshot količina i cijena u trenutku otvaranja
    final drinks = await drinksCol(cafeId).get();
    final openingSnapshot = <String, int>{};
    final pricesAtOpen = <String, int>{};

    for (final d in drinks.docs) {
      final data = d.data();
      openingSnapshot[d.id] = (data['quantity'] as num?)?.toInt() ?? 0;
      pricesAtOpen[d.id] = (data['price'] as num?)?.toInt() ?? 0;
    }

    await cafes(cafeId).add({
      'status': 'OPEN',
      'openedByUid': openedByUid,
      'openedByName': openedByName,
      'openedAt': FieldValue.serverTimestamp(),
      'openingSnapshot': openingSnapshot,
      'pricesAtOpen': pricesAtOpen,
    });
  }

  Future<void> addRestock({
    required String cafeId,
    required String shiftId,
    required String drinkId,
    required int delta,
    required String byUid,
    required String byName,
  }) async {
    final batch = _fs.batch();
    // 1) povećaj zalihu
    batch.update(drinksCol(cafeId).doc(drinkId), {'quantity': FieldValue.increment(delta)});
    // 2) restock log
    batch.set(logsCol(cafeId).doc(), {
      'type': 'restock',
      'shiftId': shiftId,
      'drinkId': drinkId,
      'delta': delta,
      'byUid': byUid,
      'byName': byName,
      'at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Zatvaranje: predaj closing snapshot + finansije → status SUBMITTED
  Future<void> submitShift({
    required String cafeId,
    required String shiftId,
    required Map<String, int> closingSnapshot,
    required int cashCounted,
    required int expensesTotal,
  }) async {
    await cafes(cafeId).doc(shiftId).update({
      'status': 'SUBMITTED',
      'closingSnapshot': closingSnapshot,
      'cashCounted': cashCounted,
      'expensesTotal': expensesTotal,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Manager accept
  Future<void> acceptShift({required String cafeId, required String shiftId, required String acceptedByUid}) async {
    await cafes(cafeId).doc(shiftId).update({
      'status': 'ACCEPTED',
      'acceptedByUid': acceptedByUid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sumiraj restock po artiklu za dati shift
  Future<Map<String, int>> loadRestockForShift({required String cafeId, required String shiftId}) async {
    final qs = await logsCol(cafeId).where('type', isEqualTo: 'restock').where('shiftId', isEqualTo: shiftId).get();

    final map = <String, int>{};
    for (final d in qs.docs) {
      final drinkId = d['drinkId'] as String;
      final delta = (d['delta'] as num).toInt();
      map.update(drinkId, (p) => p + delta, ifAbsent: () => delta);
    }
    return map;
  }
}
