import 'package:equatable/equatable.dart';

class HandoverState extends Equatable {
  final bool loading;
  final String? error;
  final String? activeSessionId; // null ako nema otvorene
  final int cashCents; // lokalni unos
  final int expensesCents; // lokalni unos

  const HandoverState({
    required this.loading,
    required this.error,
    required this.activeSessionId,
    required this.cashCents,
    required this.expensesCents,
  });

  factory HandoverState.initial() =>
      const HandoverState(loading: false, error: null, activeSessionId: null, cashCents: 0, expensesCents: 0);

  // Sentinel pattern: omogućava eksplicitno postavljanje na null.
  static const _unset = Object();

  HandoverState copyWith({
    bool? loading,
    Object? error = _unset, // String? ili null, ali samo ako je prosleđeno
    Object? activeSessionId = _unset, // String? ili null, ali samo ako je prosleđeno
    int? cashCents,
    int? expensesCents,
  }) {
    return HandoverState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      activeSessionId: identical(activeSessionId, _unset) ? this.activeSessionId : activeSessionId as String?,
      cashCents: cashCents ?? this.cashCents,
      expensesCents: expensesCents ?? this.expensesCents,
    );
  }

  @override
  List<Object?> get props => [loading, error, activeSessionId, cashCents, expensesCents];
}
