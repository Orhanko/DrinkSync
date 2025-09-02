import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../menu/data/drinks_repository.dart';
import 'bloc/drinks_bloc.dart';
import 'bloc/drinks_event.dart';
import 'bloc/drinks_state.dart';
import '../../../widgets/drink_tile.dart';

class MenuScreen extends StatelessWidget {
  final String cafeId;
  final bool isManager;
  const MenuScreen({super.key, required this.cafeId, required this.isManager});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => DrinksBloc(repo: DrinksRepository(), cafeId: cafeId),
      child: Scaffold(
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

                final subtitle = (isManager && d.updatedByName != null && d.updatedAt != null)
                    ? 'Zadnje ažurirao: ${d.updatedByName} • ${TimeOfDay.fromDateTime(d.updatedAt!).format(context)}'
                    : null;

                return DrinkTile(
                  key: ValueKey(d.id),
                  drinkId: d.id,
                  name: d.name,
                  quantity: qty,
                  originalQuantity: d.quantity,
                  syncToken: 0, // ostavljeno radi kompatibilnosti sa widgetom
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
                          : () {
                              final u = FirebaseAuth.instance.currentUser;
                              context.read<DrinksBloc>().add(
                                DrinksConfirm(
                                  cafeId: cafeId,
                                  updatedByUid: u?.uid,
                                  updatedByName: u?.displayName ?? u?.email,
                                ),
                              );
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
