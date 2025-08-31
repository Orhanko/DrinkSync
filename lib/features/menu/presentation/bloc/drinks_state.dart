import '../../domain/drink.dart';

class DrinksState {
  final List<Drink> drinks; // server lista
  final Map<String, int> localQty; // lokalne izmjene (id -> qty)
  final bool saving;

  const DrinksState({required this.drinks, required this.localQty, required this.saving});

  factory DrinksState.initial() => const DrinksState(drinks: [], localQty: {}, saving: false);

  DrinksState copyWith({List<Drink>? drinks, Map<String, int>? localQty, bool? saving}) {
    return DrinksState(
      drinks: drinks ?? this.drinks,
      localQty: localQty ?? this.localQty,
      saving: saving ?? this.saving,
    );
  }

  int originalQty(String id) {
    return drinks.firstWhere((d) => d.id == id).quantity;
  }

  int currentQty(String id) {
    return localQty[id] ?? originalQty(id);
  }

  bool isModified(String id) => currentQty(id) != originalQty(id);

  int get modifiedCount {
    int c = 0;
    for (final d in drinks) {
      final cur = localQty[d.id];
      if (cur != null && cur != d.quantity) c++;
    }
    return c;
  }

  Map<String, int> deltas() {
    final m = <String, int>{};
    for (final d in drinks) {
      final cur = localQty[d.id];
      if (cur != null && cur != d.quantity) {
        m[d.id] = cur - d.quantity;
      }
    }
    return m;
  }
}
