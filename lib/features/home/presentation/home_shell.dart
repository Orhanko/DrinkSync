import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drinksync/features/handover/presentation/handover_tab.dart';
import 'package:drinksync/features/logs/presentation/logs_screen.dart';
import 'package:drinksync/features/menu/presentation/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeShell extends StatefulWidget {
  final String cafeId;
  final bool isManager;
  const HomeShell({super.key, required this.cafeId, required this.isManager});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<String> _getCafeName() async {
    final doc = await FirebaseFirestore.instance.collection('cafes').doc(widget.cafeId).get();
    if (doc.exists && doc.data()?['name'] != null) {
      return doc["name"] as String;
    }
    return widget.cafeId;
  }

  @override
  Widget build(BuildContext context) {
    // Tabovi: za sve -> Inventar + Predaja smjene
    // Ako je manager, po želji dodaj i "Logovi".
    final tabs = <Widget>[
      MenuScreen(cafeId: widget.cafeId, isManager: widget.isManager),
      HandoverTab(cafeId: widget.cafeId),
      if (widget.isManager) LogsTab(cafeId: widget.cafeId),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventar'),
      const BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Predaja smjene'),
      if (widget.isManager) const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Logovi'),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: FutureBuilder<String>(
          future: _getCafeName(),
          builder: (context, snapshot) {
            final cafeName = snapshot.data ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DRINKSYNC',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                if (cafeName.isNotEmpty)
                  Text(
                    cafeName,
                    style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Odjava',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: items.map((e) => NavigationDestination(icon: e.icon, label: e.label ?? '')).toList(),
      ),
    );
  }
}
