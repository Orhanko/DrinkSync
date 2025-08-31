import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drinksync/features/membership/presentation/member_guard.dart';
import 'package:drinksync/features/menu/presentation/menu_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SignInPage();
        return const _ActiveCafeRouter();
      },
    );
  }
}

class _ActiveCafeRouter extends StatelessWidget {
  const _ActiveCafeRouter();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!.data();
        final activeCafeId = data?['activeCafeId'] as String?;
        if (activeCafeId == null || activeCafeId.isEmpty) {
          return const _NoCafeScreen();
        }
        // Guard koji provjerava membership/rolu pa tek onda ulazi u MenuScreen
        return MemberGuard(
          cafeId: activeCafeId,
          builder: (context, role) => MenuScreen(cafeId: activeCafeId, isManager: role == 'manager'),
        );
      },
    );
  }
}

class _NoCafeScreen extends StatelessWidget {
  const _NoCafeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nema aktivnog kafića')),
      body: const Center(
        child: Text(
          'Postavi users/{uid}.activeCafeId u Firestore-u.\nTrenutni korisnik nema dodijeljen kafić.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
