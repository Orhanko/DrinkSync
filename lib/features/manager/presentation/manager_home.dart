import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:drinksync/features/menu/presentation/menu_screen.dart';
import 'package:drinksync/features/logs/presentation/logs_screen.dart';

class ManagerHome extends StatelessWidget {
  final String cafeId;
  const ManagerHome({super.key, required this.cafeId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final memberDoc = FirebaseFirestore.instance
        .collection('cafes')
        .doc(cafeId)
        .collection('members')
        .doc(uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: memberDoc,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data?.data();
        final role = data?['role'] as String?;
        final isManager = role == 'manager';

        if (!isManager) {
          // Staff vidi samo menu (bez tabova)
          return MenuScreen(cafeId: cafeId, isManager: false);
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Manager'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Menu'),
                  Tab(icon: Icon(Icons.history), text: 'Logs'),
                ],
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(), // opcionalno — da ne “swipe-a”
              children: [
                MenuScreen(cafeId: cafeId, isManager: true),
                LogsTab(cafeId: cafeId),
              ],
            ),
          ),
        );
      },
    );
  }
}
