import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drinksync/features/shifts/data/shift_repository.dart';
import '../bloc/shift_bloc.dart';
import '../bloc/shift_event.dart';
import '../bloc/shift_state.dart';
import '../widgets/restock_dialog.dart';

class ShiftScreen extends StatelessWidget {
  final String cafeId;
  const ShiftScreen({super.key, required this.cafeId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return BlocProvider(
      create: (_) => ShiftBloc(repo: ShiftsRepository(), cafeId: cafeId, uid: user.uid),
      child: _ShiftView(cafeId: cafeId, userName: user.displayName ?? user.email ?? user.uid),
    );
  }
}

class _ShiftView extends StatelessWidget {
  final String cafeId;
  final String userName;
  const _ShiftView({required this.cafeId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, s) {
        if (s.loading) return const Center(child: CircularProgressIndicator());

        // Nema otvorene smjene?
        if (s.shift == null) {
          return Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Otvori smjenu'),
              onPressed: () =>
                  context.read<ShiftBloc>().add(ShiftOpen(cafeId, FirebaseAuth.instance.currentUser!.uid, userName)),
            ),
          );
        }

        final shift = s.shift!;
        final drinks = s.drinks;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Smjena – zatvaranje'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Dopuna',
                onPressed: () async {
                  final res = await showDialog<RestockResult>(
                    context: context,
                    builder: (_) => RestockDialog(drinks: drinks),
                  );
                  if (res != null && res.delta > 0) {
                    final u = FirebaseAuth.instance.currentUser!;
                    context.read<ShiftBloc>().add(
                      ShiftAddRestock(res.drinkId, res.delta, u.uid, u.displayName ?? u.email ?? u.uid),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dopuna zabilježena.')));
                  }
                },
                icon: const Icon(Icons.inventory_2),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: drinks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = drinks[i];
              final open = shift.openingSnapshot[d.id] ?? 0;
              final restock = s.restock[d.id] ?? 0;
              final close = s.closingSnapshot[d.id] ?? 0;
              final sold = open + restock - close;

              return ListTile(
                title: Text(d.name),
                subtitle: Text('Otvaranje: $open • Dopuna: $restock • Prodato: $sold'),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: close > 0
                            ? () => context.read<ShiftBloc>().add(ShiftSetClosingQty(d.id, close - 1))
                            : null,
                      ),
                      Text('$close', style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => context.read<ShiftBloc>().add(ShiftSetClosingQty(d.id, close + 1)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Gotovina (feninga)'),
                        onChanged: (v) => context.read<ShiftBloc>().add(ShiftSetCash(int.tryParse(v) ?? 0)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Rashodi (feninga)'),
                        onChanged: (v) => context.read<ShiftBloc>().add(ShiftSetExpenses(int.tryParse(v) ?? 0)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Prihod: ${(s.totalRevenue / 100).toStringAsFixed(2)} KM'),
                    const SizedBox(width: 16),
                    Text(
                      'Razlika: ${(s.discrepancy / 100).toStringAsFixed(2)} KM',
                      style: TextStyle(color: s.discrepancy == 0 ? Colors.green : Colors.red),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: s.submitting ? null : () => context.read<ShiftBloc>().add(ShiftSubmit(cafeId)),
                      icon: s.submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.flag),
                      label: const Text('Predaj smjenu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
