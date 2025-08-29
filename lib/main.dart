import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DrinkSyncApp());
}

class DrinkSyncApp extends StatelessWidget {
  const DrinkSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrinkSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD85151))),
      home: const AuthGate(),
    );
  }
}

/* -------------------- AUTH GATE -------------------- */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SignInPage();
        return const ActiveCafeRouter();
      },
    );
  }
}

/* -------------------- SIGN IN -------------------- */

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DrinkSync – prijava'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Lozinka'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _loading ? null : _signIn,
              child: _loading ? const CircularProgressIndicator() : const Text('Prijavi se'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------- ROUTER: UČITA activeCafeId ----------- */

class ActiveCafeRouter extends StatelessWidget {
  const ActiveCafeRouter({super.key});

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
          return const NoCafeScreen();
        }
        return MenuScreen(cafeId: activeCafeId);
      },
    );
  }
}

class NoCafeScreen extends StatelessWidget {
  const NoCafeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nema aktivnog kafića')),
      body: Center(
        child: Text(
          'Postavi users/{uid}.activeCafeId u Firestore-u.\n'
          'Trenutni korisnik nema dodijeljen kafić.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/* -------------------- MENU (lista pića) -------------------- */

class MenuScreen extends StatelessWidget {
  final String cafeId;
  MenuScreen({super.key, required this.cafeId});
  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    final drinksCol = FirebaseFirestore.instance.collection('cafes').doc(cafeId).collection('drinks');
    if (user != null) {
      debugPrint("Prijavljen user: email=${user!.email}, uid=${user!.uid}");
    } else {
      debugPrint("Niko nije prijavljen");
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('DrinkSync — $cafeId'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: drinksCol.orderBy('name').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Greška: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nema artikala.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['name'] as String?) ?? 'N/A';
              final qty = (d['quantity'] as num?)?.toInt() ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$qty', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
