import '../../domain/drink.dart';

class DrinksState {
  final List<Drink> drinks; // server lista (stream)
  final Map<String, int> localQty; // lokalni override po id-u
  final bool saving; // u toku "Potvrdi"

  const DrinksState({required this.drinks, required this.localQty, required this.saving});

  factory DrinksState.initial() => const DrinksState(drinks: [], localQty: {}, saving: false);

  DrinksState copyWith({List<Drink>? drinks, Map<String, int>? localQty, bool? saving}) {
    return DrinksState(
      drinks: drinks ?? this.drinks,
      localQty: localQty ?? this.localQty,
      saving: saving ?? this.saving,
    );
  }

  /// trenutna (prikazana) količina = lokalna ili server
  int currentQty(String id) {
    final local = localQty[id];
    if (local != null) return local;
    final d = drinks.firstWhere(
      (x) => x.id == id,
      orElse: () => const Drink(id: '', name: '', quantity: 0),
    );
    return d.quantity;
  }

  /// broj izmijenjenih artikala
  int get modifiedCount {
    int c = 0;
    for (final d in drinks) {
      final local = localQty[d.id];
      if (local != null && local != d.quantity) c++;
    }
    return c;
  }

  /// izračunaj delte u odnosu na server vrijednosti
  Map<String, int> deltas() {
    final out = <String, int>{};
    for (final d in drinks) {
      final local = localQty[d.id];
      if (local == null) continue;
      final delta = local - d.quantity;
      if (delta != 0) out[d.id] = delta;
    }
    return out;
  }
}
