import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drinksync/features/menu/data/drinks_repository.dart';
import 'package:drinksync/features/menu/presentation/bloc/drinks_bloc.dart';
import 'package:drinksync/features/menu/presentation/bloc/drinks_event.dart';
import 'package:drinksync/features/menu/presentation/bloc/drinks_state.dart';
import 'package:drinksync/widgets/drink_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuScreen extends StatefulWidget {
  final String cafeId;
  final bool isManager;
  const MenuScreen({super.key, required this.cafeId, required this.isManager});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _myDisplayNameCache;
  late final Future<String?> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = _getMyDisplayName();
  }

  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  Future<String?> _getMyDisplayName() async {
    if (_myDisplayNameCache != null) return _myDisplayNameCache;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return user?.displayName ?? user?.email ?? null;

    try {
      final snap = await _fs.collection('users').doc(uid).get();
      final nameFromUsers = snap.data()?['displayName'] as String?;
      _myDisplayNameCache = nameFromUsers ?? user?.displayName ?? user?.email ?? uid;
      return _myDisplayNameCache;
    } catch (_) {
      return user?.displayName ?? user?.email ?? uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => DrinksBloc(repo: DrinksRepository(), cafeId: widget.cafeId),
      child: Scaffold(
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
        body: BlocBuilder<DrinksBloc, DrinksState>(
          builder: (context, state) {
            final drinks = state.drinks;
            if (drinks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: drinks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = drinks[i];
                final qty = state.currentQty(d.id);

                final subtitle = (widget.isManager && d.updatedByName != null && d.updatedAt != null)
                    ? 'Zadnje ažurirao: ${d.updatedByName} • ${TimeOfDay.fromDateTime(d.updatedAt!).format(context)}'
                    : null;

                return DrinkTile(
                  key: ValueKey(d.id),
                  drinkId: d.id,
                  name: d.name,
                  quantity: qty,
                  originalQuantity: d.quantity,
                  syncToken: 0, // više ne koristimo, ostavljeno radi kompatibilnosti
                  onChanged: (newQty) => context.read<DrinksBloc>().add(DrinksSetQty(d.id, newQty)),
                  onRevert: () => context.read<DrinksBloc>().add(DrinksRevertOne(d.id)),
                  subtitle: subtitle,
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
            child: BlocBuilder<DrinksBloc, DrinksState>(
              buildWhen: (p, n) => p.modifiedCount != n.modifiedCount || p.saving != n.saving,
              builder: (context, state) {
                return Row(
                  children: [
                    if (state.modifiedCount > 0)
                      TextButton.icon(
                        onPressed: state.saving ? null : () => context.read<DrinksBloc>().add(const DrinksResetAll()),
                        icon: const Icon(Icons.restore),
                        label: const Text('Poništi sve'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: (state.modifiedCount == 0 || state.saving)
                          ? null
                          : () async {
                              final user = FirebaseAuth.instance.currentUser;
                              context.read<DrinksBloc>().add(
                                DrinksConfirm(
                                  cafeId: widget.cafeId,
                                  updatedByUid: user?.uid,
                                  updatedByName: _myDisplayNameCache ?? user?.displayName ?? user?.email,
                                ),
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Izmjene su sačuvane.')));
                            },
                      icon: state.saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(state.modifiedCount == 0 ? 'Potvrdi' : 'Potvrdi (${state.modifiedCount})'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
