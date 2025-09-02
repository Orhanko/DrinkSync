
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drinksync/features/logs/domain/log_record.dart';

class LogsRepository {
  final FirebaseFirestore _fs;
  LogsRepository({FirebaseFirestore? fs}) : _fs = fs ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _logsCol(String cafeId) =>
      _fs.collection('cafes').doc(cafeId).collection('logs');

  Stream<List<LogRecord>> streamLogs(String cafeId, {int limit = 100}) {
    return _logsCol(cafeId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LogRecord.fromFirestore(d.id, d.data())).toList());
  }
}
