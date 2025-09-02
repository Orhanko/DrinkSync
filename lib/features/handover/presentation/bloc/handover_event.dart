import 'package:equatable/equatable.dart';

abstract class HandoverEvent extends Equatable {
  const HandoverEvent();
  @override
  List<Object?> get props => [];
}

class HandoverInit extends HandoverEvent {
  final String cafeId;
  const HandoverInit(this.cafeId);
  @override
  List<Object?> get props => [cafeId];
}

class HandoverStart extends HandoverEvent {
  final String cafeId;
  final String openedByName;
  const HandoverStart({required this.cafeId, required this.openedByName});
  @override
  List<Object?> get props => [cafeId, openedByName];
}

class HandoverCashChanged extends HandoverEvent {
  final int cashCents;
  const HandoverCashChanged(this.cashCents);
  @override
  List<Object?> get props => [cashCents];
}

class HandoverExpensesChanged extends HandoverEvent {
  final int expensesCents;
  const HandoverExpensesChanged(this.expensesCents);
  @override
  List<Object?> get props => [expensesCents];
}

class HandoverClose extends HandoverEvent {
  final String cafeId;
  final String closedByName;
  const HandoverClose({required this.cafeId, required this.closedByName});
  @override
  List<Object?> get props => [cafeId, closedByName];
}
