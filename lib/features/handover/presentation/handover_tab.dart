import 'package:drinksync/features/handover/data/handover_repository.dart';
import 'package:drinksync/features/handover/presentation/bloc/handover_bloc.dart';
import 'package:drinksync/features/handover/presentation/bloc/handover_event.dart';
import 'package:drinksync/features/handover/presentation/bloc/handover_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HandoverTab extends StatelessWidget {
  final String cafeId;
  const HandoverTab({super.key, required this.cafeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HandoverBloc(repo: HandoverRepository())..add(HandoverInit(cafeId)),
      child: BlocConsumer<HandoverBloc, HandoverState>(
        listenWhen: (p, n) => p.error != n.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final hasOpen = state.activeSessionId != null;

          // Potpuno zamijeni subtree kad se promijeni hasOpen
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: hasOpen
                ? _ActiveHandoverView(
                    key: const ValueKey('active'),
                    cafeId: cafeId,
                    loading: state.loading,
                    cashCents: state.cashCents,
                    expensesCents: state.expensesCents,
                  )
                : _StartHandoverView(key: const ValueKey('start'), cafeId: cafeId, loading: state.loading),
          );
        },
      ),
    );
  }
}

/* -------------------- START VIEW (nema aktivne smjene) -------------------- */

class _StartHandoverView extends StatefulWidget {
  final String cafeId;
  final bool loading;
  const _StartHandoverView({super.key, required this.cafeId, required this.loading});

  @override
  State<_StartHandoverView> createState() => _StartHandoverViewState();
}

class _StartHandoverViewState extends State<_StartHandoverView> {
  Future<String?> _myName() async {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email ?? u?.uid;
  }

  final _openingCashCtl = TextEditingController();
  @override
  void dispose() {
    _openingCashCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const ValueKey('start_content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.loading) const LinearProgressIndicator(),
          const Text('Nema aktivne smjene.'),
          TextField(
            controller: _openingCashCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Početni novac (KM)',
              prefixText: 'KM ',
              hintText: 'npr. 100.00',
            ),
          ),
          FutureBuilder<String?>(
            future: _myName(),
            builder: (context, s) {
              final name = s.data ?? '';
              return FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Započni zapis smjene'),
                onPressed: widget.loading
                    ? null
                    : () {
                        final openingCashCents = _toCents(_openingCashCtl.text);
                        context.read<HandoverBloc>().add(
                          HandoverStart(
                            cafeId: widget.cafeId,
                            openedByName: name,
                            openingCashCents: openingCashCents, // NEW
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
    );
  }
}

// dodaj helper (možeš iskoristiti onaj što već imaš u _ActiveHandoverView)
int _toCents(String input) {
  final norm = input.replaceAll(',', '.').trim();
  if (norm.isEmpty) return 0;
  final parts = norm.split('.');
  if (parts.length == 1) {
    final i = int.tryParse(parts[0]) ?? 0;
    return i * 100;
  }
  final whole = int.tryParse(parts[0]) ?? 0;
  var frac = parts[1];
  if (frac.length == 1) frac = '${frac}0';
  if (frac.length > 2) frac = frac.substring(0, 2);
  final f = int.tryParse(frac) ?? 0;
  return whole * 100 + f;
}

/* -------------------- ACTIVE VIEW (smjena u toku) -------------------- */

class _ActiveHandoverView extends StatefulWidget {
  final String cafeId;
  final bool loading;
  final int cashCents;
  final int expensesCents;

  const _ActiveHandoverView({
    super.key,
    required this.cafeId,
    required this.loading,
    required this.cashCents,
    required this.expensesCents,
  });

  @override
  State<_ActiveHandoverView> createState() => _ActiveHandoverViewState();
}

class _ActiveHandoverViewState extends State<_ActiveHandoverView> {
  late final TextEditingController _cashCtl;
  late final TextEditingController _expCtl;
  final _focusCash = FocusNode();
  final _focusExp = FocusNode();

  @override
  void initState() {
    super.initState();
    _cashCtl = TextEditingController(text: _fromCents(widget.cashCents));
    _expCtl = TextEditingController(text: _fromCents(widget.expensesCents));
  }

  @override
  void didUpdateWidget(covariant _ActiveHandoverView old) {
    super.didUpdateWidget(old);
    // Syncuj polja ako ih promijeni bloc (npr. reset nakon operacija)
    if (old.cashCents != widget.cashCents) {
      _cashCtl.text = _fromCents(widget.cashCents);
    }
    if (old.expensesCents != widget.expensesCents) {
      _expCtl.text = _fromCents(widget.expensesCents);
    }
  }

  @override
  void dispose() {
    _cashCtl.dispose();
    _expCtl.dispose();
    _focusCash.dispose();
    _focusExp.dispose();
    super.dispose();
  }

  Future<String?> _myName() async {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email ?? u?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('active_content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.loading) const LinearProgressIndicator(),
          const Text('Aktivna smjena je u toku.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashCtl,
                  focusNode: _focusCash,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}$'))],
                  decoration: const InputDecoration(labelText: 'Gotovina (KM)', prefixText: 'KM '),
                  onChanged: (txt) => context.read<HandoverBloc>().add(HandoverCashChanged(_toCents(txt))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _expCtl,
                  focusNode: _focusExp,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}$'))],
                  decoration: const InputDecoration(labelText: 'Rashod (KM)', prefixText: 'KM '),
                  onChanged: (txt) => context.read<HandoverBloc>().add(HandoverExpensesChanged(_toCents(txt))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<String?>(
            future: _myName(),
            builder: (context, s) {
              final name = s.data ?? '';
              return FilledButton.icon(
                icon: widget.loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(widget.loading ? 'Zatvaram...' : 'Zatvori smjenu'),
                onPressed: widget.loading
                    ? null
                    : () {
                        // skini fokus da se tastatura zatvori
                        _focusCash.unfocus();
                        _focusExp.unfocus();
                        context.read<HandoverBloc>().add(HandoverClose(cafeId: widget.cafeId, closedByName: name));
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  // helpers
  int _toCents(String input) {
    final norm = input.replaceAll(',', '.').trim();
    if (norm.isEmpty) return 0;
    final parts = norm.split('.');
    if (parts.length == 1) {
      final i = int.tryParse(parts[0]) ?? 0;
      return i * 100;
    }
    final whole = int.tryParse(parts[0]) ?? 0;
    var frac = parts[1];
    if (frac.length == 1) frac = '${frac}0';
    if (frac.length > 2) frac = frac.substring(0, 2);
    final f = int.tryParse(frac) ?? 0;
    return whole * 100 + f;
  }

  String _fromCents(int cents) {
    final abs = cents.abs();
    final km = abs ~/ 100;
    final f = abs % 100;
    final sign = cents < 0 ? '-' : '';
    return '$sign$km.${f.toString().padLeft(2, '0')}';
  }
}
