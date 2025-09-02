import '../../domain/shift.dart';
import '../../../menu/domain/drink.dart';

class ShiftState {
  final Shift? shift; // aktivna ili null
  final List<Drink> drinks; // iz menija (za nazive, redoslijed)
  final Map<String, int> closingSnapshot; // lokalni unos pri zatvaranju
  final int cashCounted;
  final int expensesTotal;
  final Map<String, int> restock; // sabrano iz logova
  final bool loading;
  final bool submitting;
  final String? error;

  const ShiftState({
    required this.shift,
    required this.drinks,
    required this.closingSnapshot,
    required this.cashCounted,
    required this.expensesTotal,
    required this.restock,
    required this.loading,
    required this.submitting,
    this.error,
  });

  factory ShiftState.initial() => const ShiftState(
    shift: null,
    drinks: [],
    closingSnapshot: {},
    cashCounted: 0,
    expensesTotal: 0,
    restock: {},
    loading: true,
    submitting: false,
  );

  ShiftState copyWith({
    Shift? shift,
    List<Drink>? drinks,
    Map<String, int>? closingSnapshot,
    int? cashCounted,
    int? expensesTotal,
    Map<String, int>? restock,
    bool? loading,
    bool? submitting,
    String? error,
  }) {
    return ShiftState(
      shift: shift ?? this.shift,
      drinks: drinks ?? this.drinks,
      closingSnapshot: closingSnapshot ?? this.closingSnapshot,
      cashCounted: cashCounted ?? this.cashCounted,
      expensesTotal: expensesTotal ?? this.expensesTotal,
      restock: restock ?? this.restock,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }

  // helpers za obračun
  int closingFor(String id) => closingSnapshot[id] ?? 0;
  int openingFor(String id) => shift?.openingSnapshot[id] ?? 0;
  int restockFor(String id) => restock[id] ?? 0;
  int priceFor(String id) => shift?.pricesAtOpen[id] ?? 0;

  int soldFor(String id) {
    // sold = opening + restock - closing
    return openingFor(id) + restockFor(id) - closingFor(id);
  }

  int revenueFor(String id) => soldFor(id) * priceFor(id);

  int get totalRevenue => drinks.fold(0, (sum, d) => sum + revenueFor(d.id));

  int get discrepancy => cashCounted - (totalRevenue - expensesTotal);
}
