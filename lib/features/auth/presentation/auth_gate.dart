import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drinksync/features/home/presentation/home_shell.dart'; // ⬅️ novi shell sa tabovima
import 'package:drinksync/features/membership/presentation/member_guard.dart';
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

        // ✅ Provjeri članstvo/rolu i otvori HomeShell (tabovi: Inventar, Predaja smjene, Logovi*)
        return MemberGuard(
          cafeId: activeCafeId,
          builder: (context, role) {
            final isManager = role == 'manager';
            return HomeShell(
              cafeId: activeCafeId,
              isManager: isManager, // shell odlučuje koji tabovi su vidljivi
            );
          },
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
