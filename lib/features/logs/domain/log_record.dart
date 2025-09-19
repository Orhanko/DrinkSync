class LogRecord {
  final String id;
  final String drinkId;
  final int? before;
  final int? after;
  final int? delta;
  final String? updatedBy;
  final String? updatedByName;
  final DateTime? createdAt;
  final String source;

  LogRecord({
    required this.id,
    required this.drinkId,
    this.before,
    this.after,
    this.delta,
    this.updatedBy,
    this.updatedByName,
    this.createdAt,
    required this.source,
  });

  factory LogRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return LogRecord(
      id: id,
      drinkId: data['drinkId'] as String? ?? 'unknown',
      before: (data['before'] as num?)?.toInt(),
      after: (data['after'] as num?)?.toInt(),
      delta: (data['delta'] as num?)?.toInt(),
      updatedBy: data['updatedBy'] as String?,
      updatedByName: data['updatedByName'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      source: (data['collection'] as String?) ?? "proba",
    );
  }
}
