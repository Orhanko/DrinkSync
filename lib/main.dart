import 'package:drinksync/widgets/drink_tile.dart';
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

class MenuScreen extends StatefulWidget {
  final String cafeId;
  const MenuScreen({super.key, required this.cafeId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Map<String, int> _originalQty = {}; // drinkId -> server qty
  final Map<String, int> _localQty = {}; // drinkId -> local qty (samo izmjene)
  final Set<String> _modified = {}; // izmijenjeni artikli
  String? _myDisplayNameCache;
  // sync token forsira da svaki DrinkTile prihvati parent/server vrijednost nakon reset/confirm
  int _syncToken = 0;
  // lagano pratimo state snimanja bez re-rendera cijele liste
  final ValueNotifier<bool> _savingVN = ValueNotifier<bool>(false);
  late final Future<String?> _nameFuture;

  final ValueNotifier<int> _modifiedCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _nameFuture = _getMyDisplayName();
  }

  CollectionReference<Map<String, dynamic>> get _drinksCol =>
      FirebaseFirestore.instance.collection('cafes').doc(widget.cafeId).collection('drinks');

  int _currentQtyFor(String id) => _localQty[id] ?? _originalQty[id] ?? 0;

  void _markIfChanged(String id) {
    final cur = _localQty[id];
    final orig = _originalQty[id];
    if (cur == null || cur == orig) {
      _localQty.remove(id);
      _modified.remove(id);
    } else {
      _modified.add(id);
    }
    _modifiedCount.value = _modified.length;
  }

  Future<String?> _getMyDisplayName() async {
    if (_myDisplayNameCache != null) return _myDisplayNameCache;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return user?.displayName ?? user?.email ?? null;

    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final nameFromUsers = snap.data()?['displayName'] as String?;
      _myDisplayNameCache = nameFromUsers ?? user?.displayName ?? user?.email ?? uid;
      return _myDisplayNameCache;
    } catch (_) {
      // fallback na Auth podatke ako users/{uid} nije dostupan
      return user?.displayName ?? user?.email ?? uid;
    }
  }
  // ...

  void _revertOne(String id) {
    _localQty.remove(id);
    _modified.remove(id);
    _modifiedCount.value = _modified.length;
  }

  void _resetAll() {
    _localQty.clear();
    _modified.clear();
    _modifiedCount.value = 0;
    setState(() {}); // samo lokalni redraw bez globalnog fadera/tokena
  }

  Future<void> _confirmChanges() async {
    if (_modified.isEmpty) return;
    _savingVN.value = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final authUser = FirebaseAuth.instance.currentUser;
      final uid = authUser?.uid;
      final byName = await _getMyDisplayName();

      for (final id in _modified) {
        final local = _localQty[id];
        final orig = _originalQty[id];
        if (local == null || orig == null) continue;
        final delta = local - orig;
        if (delta == 0) continue;
        batch.update(_drinksCol.doc(id), {
          'quantity': FieldValue.increment(delta),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
          'updatedByName': byName,
        });
      }

      await batch.commit();

      // Lokalno očistimo; Stream će ubrzo donijeti svježe server vrijednosti
      _localQty.clear();
      _modified.clear();
      _modifiedCount.value = 0;
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izmjene su sačuvane.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Greška pri snimanju: $e')));
      }
    } finally {
      _savingVN.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FutureBuilder<String?>(
          future: _nameFuture,
          builder: (context, snapshot) {
            final name = snapshot.data;
            final displayTitle = (name != null && name.isNotEmpty) ? '$name - ${widget.cafeId}' : 'DrinkSync';
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('DrinkSync');
            }
            return Text(displayTitle);
          },
        ),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cafes')
            .doc(widget.cafeId)
            .collection('members')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, memberSnap) {
          if (memberSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!memberSnap.hasData || memberSnap.data?.data() == null) {
            // nije član ili nema dokumenta
            return const Center(child: Text('Nemate pristup ovom kafiću.'));
          }

          final role = memberSnap.data!.data()!['role'] as String?; // 'manager' ili 'staff'
          final isManager = role == 'manager';

          // ORIGINALNI StreamBuilder za drinks sada ide OVDJE:
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _drinksCol.orderBy('name').snapshots(),
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

              // osvježi originalne vrijednosti (ali NE diraj lokalne izmjene)
              for (final doc in docs) {
                final id = doc.id;
                final serverQty = (doc.data()['quantity'] as num?)?.toInt() ?? 0;
                if (!_modified.contains(id)) {
                  _originalQty[id] = serverQty;
                }
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final id = doc.id;
                  final name = (doc.data()['name'] as String?) ?? 'N/A';
                  final qty = _currentQtyFor(id);

                  // meta polja
                  final updatedByName = doc.data()['updatedByName'] as String?;
                  final updatedAtTs = doc.data()['updatedAt'] as Timestamp?;
                  final updatedAt = updatedAtTs?.toDate();

                  // samo manager vidi subtitle
                  final subtitle = (isManager && updatedByName != null && updatedAt != null)
                      ? 'Zadnje ažurirao: $updatedByName • ${TimeOfDay.fromDateTime(updatedAt).format(context)}'
                      : null;

                  return DrinkTile(
                    key: ValueKey(id), // STABILAN ključ po artiklu
                    drinkId: id,
                    name: name,
                    quantity: qty,
                    originalQuantity: _originalQty[id] ?? 0,
                    syncToken: _syncToken, // ostaje za slučaj da ga koristimo u tile-u
                    onChanged: (newValue) {
                      _localQty[id] = newValue;
                      _markIfChanged(id);
                    },
                    onRevert: () => _revertOne(id),
                    subtitle: subtitle,
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: _modifiedCount,
            builder: (context, modifiedCount, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: _savingVN,
                builder: (context, saving, __) {
                  return Row(
                    children: [
                      if (modifiedCount > 0)
                        TextButton.icon(
                          onPressed: saving ? null : _resetAll,
                          icon: const Icon(Icons.restore),
                          label: const Text('Poništi sve'),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: (modifiedCount == 0 || saving) ? null : _confirmChanges,
                        icon: saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(modifiedCount == 0 ? 'Potvrdi' : 'Potvrdi ($modifiedCount)'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// class _QtyStepper extends StatelessWidget {
//   final int quantity;
//   final VoidCallback onInc;
//   final VoidCallback onDec;
//   const _QtyStepper({required this.quantity, required this.onInc, required this.onDec});

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(
//           visualDensity: VisualDensity.compact,
//           style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHighest)),
//           onPressed: quantity > 0 ? onDec : null,
//           icon: const Icon(Icons.remove),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8),
//           child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//         ),
//         IconButton(
//           visualDensity: VisualDensity.compact,
//           style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(cs.primaryContainer)),
//           onPressed: onInc,
//           icon: const Icon(Icons.add),
//         ),
//       ],
//     );
//   }
//}
