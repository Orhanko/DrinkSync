import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembershipRepository {
  final _fs = FirebaseFirestore.instance;

  Stream<String?> roleStream(String cafeId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _fs
        .collection('cafes')
        .doc(cafeId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String?);
  }
}
