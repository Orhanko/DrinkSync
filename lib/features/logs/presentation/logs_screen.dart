import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LogsTab extends StatelessWidget {
  final String cafeId;
  const LogsTab({super.key, required this.cafeId});

  @override
  Widget build(BuildContext context) {
    final qs = FirebaseFirestore.instance
        .collection('cafes')
        .doc(cafeId)
        .collection('logs')
        .orderBy('updatedAt', descending: true) // mora postojati ovo polje
        .limit(100)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: qs,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Greška: ${snap.error}')); // npr. permission-denied
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Nema logova.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final drinkId = d['drinkId'] as String? ?? '—';
            final delta = (d['delta'] as num?)?.toInt() ?? 0;
            final by = d['updatedByName'] as String? ?? d['updatedBy'] as String? ?? 'Nepoznato';
            final ts = d['updatedAt']; // može biti null dok serverTimestamp ne upiše
            final when = (ts is Timestamp) ? TimeOfDay.fromDateTime(ts.toDate()).format(context) : '…';
            final source = d['collection'] as String? ?? "proba";

            return ListTile(
              title: Text('$drinkId   ${delta >= 0 ? '+' : ''}$delta'),
              subtitle: Text('by $by • $when • $source'),
              dense: true,
            );
          },
        );
      },
    );
  }
}
