import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../menu/data/drinks_repository.dart';
import 'bloc/drinks_bloc.dart';
import 'bloc/drinks_event.dart';
import 'bloc/drinks_state.dart';
import '../../../widgets/drink_tile.dart';

class MenuScreen extends StatefulWidget {
  final String cafeId;
  final bool isManager;
  const MenuScreen({super.key, required this.cafeId, required this.isManager});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final updatedByUid = user?.uid;
    final updatedByName = user?.displayName ?? user?.email ?? 'Unknown';

    return Scaffold(
      // NEMA AppBar-a
      body: SafeArea(
        child: Column(
          children: [
            // TAB BAR CONTAINER (iznad listi)
            Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
              child: TabBar(
                controller: _tab,
                tabs: const [
                  Tab(text: 'ŠANK'),
                  Tab(text: 'SKLADIŠTE'),
                ],
              ),
            ),

            // SADRŽAJ TABOVA
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // TAB 1: ŠANK (kolekcija "drinks")
                  BlocProvider(
                    create: (_) => DrinksBloc(
                      repo: DrinksRepository(collectionName: 'drinks'),
                      cafeId: widget.cafeId,
                    )..add(const DrinksResetAll()),
                    child: _MenuTab(
                      cafeId: widget.cafeId,
                      isManager: widget.isManager,
                      updatedByUid: updatedByUid,
                      updatedByName: updatedByName,
                    ),
                  ),

                  // TAB 2: SKLADIŠTE (kolekcija "storage")
                  BlocProvider(
                    create: (_) => DrinksBloc(
                      repo: DrinksRepository(collectionName: 'storage'),
                      cafeId: widget.cafeId,
                    )..add(const DrinksResetAll()),
                    child: _MenuTab(
                      cafeId: widget.cafeId,
                      isManager: widget.isManager,
                      updatedByUid: updatedByUid,
                      updatedByName: updatedByName,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Privatni widget koji sadrži:
/// - listu artikala (Stream iz BLoC state-a)
/// - +/– preko tvojih postojećih eventa (DrinksSetQty / Inc/Dec)
/// - Poništi / Potvrdi (DrinksResetAll / DrinksConfirm)
class _MenuTab extends StatelessWidget {
  final String cafeId;
  final bool isManager;
  final String? updatedByUid;
  final String? updatedByName;

  const _MenuTab({
    required this.cafeId,
    required this.isManager,
    required this.updatedByUid,
    required this.updatedByName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // LISTA
          Expanded(
            child: BlocBuilder<DrinksBloc, DrinksState>(
              builder: (context, state) {
                final drinks = state.drinks;
                if (drinks.isEmpty) {
                  return const Center(child: Text('Nema artikala.'));
                }
                return ListView.separated(
                  padding: EdgeInsets.all(8),
                  itemCount: drinks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = drinks[i];
                    final qty = state.currentQty(d.id);

                    final subtitle = (isManager && d.updatedByName != null && d.updatedAt != null)
                        ? 'Zadnje ažurirao: ${d.updatedByName} • ${TimeOfDay.fromDateTime(d.updatedAt!).format(context)}'
                        : null;

                    return DrinkTile(
                      key: ValueKey(d.id),
                      drinkId: d.id,
                      name: d.name,
                      quantity: qty,
                      originalQuantity: d.quantity,
                      syncToken: 0, // ostavljeno radi kompatibilnosti s tvojim widgetom
                      subtitle: subtitle, // ako DrinkTile to podržava; inače ukloni
                      onChanged: (newQty) => context.read<DrinksBloc>().add(DrinksSetQty(d.id, newQty)),
                      onRevert: () => context.read<DrinksBloc>().add(DrinksRevertOne(d.id)),
                    );
                  },
                );
              },
            ),
          ),

          // BOTTOM BAR: PONIŠTI / POTVRDI
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: BlocBuilder<DrinksBloc, DrinksState>(
              builder: (context, state) {
                final disabled = state.saving || state.modifiedCount == 0;
                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: state.localQty.isEmpty
                          ? null
                          : () => context.read<DrinksBloc>().add(const DrinksResetAll()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Poništi'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: disabled
                          ? null
                          : () => context.read<DrinksBloc>().add(
                              DrinksConfirm(cafeId: cafeId, updatedByUid: updatedByUid, updatedByName: updatedByName),
                            ),
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
        ],
      ),
    );
  }
}
