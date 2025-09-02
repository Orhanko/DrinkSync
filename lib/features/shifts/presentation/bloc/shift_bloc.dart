import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drinksync/features/shifts/data/shift_repository.dart';
import 'shift_event.dart';
import 'shift_state.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftsRepository repo;
  final String cafeId;
  final String uid;

  StreamSubscription? _activeSub;

  ShiftBloc({required this.repo, required this.cafeId, required this.uid}) : super(ShiftState.initial()) {
    on<ShiftLoad>(_onLoad);
    on<ShiftOpen>(_onOpen);
    on<ShiftSetClosingQty>(_onSetClosing);
    on<ShiftSetCash>((e, emit) => emit(state.copyWith(cashCounted: e.cashCounted)));
    on<ShiftSetExpenses>((e, emit) => emit(state.copyWith(expensesTotal: e.expensesTotal)));
    on<ShiftAddRestock>(_onAddRestock);
    on<ShiftSubmit>(_onSubmit);
    on<ShiftAccept>(_onAccept);

    add(ShiftLoad(cafeId, uid));
  }

  Future<void> _onLoad(ShiftLoad e, Emitter<ShiftState> emit) async {
    emit(state.copyWith(loading: true));
    _activeSub?.cancel();

    // 1) učitaj meni pića
    final drinks = await repo.fetchAllDrinks(e.cafeId);
    emit(state.copyWith(drinks: drinks));

    // 2) slušaj aktivnu smjenu ovog korisnika
    _activeSub = repo.streamActiveShift(e.cafeId, e.uid).listen((shift) async {
      if (shift == null) {
        emit(state.copyWith(shift: null, closingSnapshot: {}, restock: {}, loading: false));
      } else {
        // učitaj sumu restocka za shift
        final restock = await repo.loadRestockForShift(cafeId: e.cafeId, shiftId: shift.id);
        emit(
          state.copyWith(
            shift: shift,
            closingSnapshot: {}, // počinje prazno dok ne unese
            restock: restock,
            loading: false,
          ),
        );
      }
    });
  }

  Future<void> _onOpen(ShiftOpen e, Emitter<ShiftState> emit) async {
    await repo.openShift(cafeId: e.cafeId, openedByUid: e.uid, openedByName: e.name);
    // _onLoad stream će dovući novu smjenu
  }

  void _onSetClosing(ShiftSetClosingQty e, Emitter<ShiftState> emit) {
    final map = Map<String, int>.from(state.closingSnapshot);
    map[e.drinkId] = e.qty;
    emit(state.copyWith(closingSnapshot: map));
  }

  Future<void> _onAddRestock(ShiftAddRestock e, Emitter<ShiftState> emit) async {
    final shift = state.shift;
    if (shift == null) return;

    await repo.addRestock(
      cafeId: cafeId,
      shiftId: shift.id,
      drinkId: e.drinkId,
      delta: e.delta,
      byUid: e.byUid,
      byName: e.byName,
    );

    // osvježi lokalno sumu restock-a (da UI odmah prikaže)
    final map = Map<String, int>.from(state.restock);
    map.update(e.drinkId, (p) => p + e.delta, ifAbsent: () => e.delta);
    emit(state.copyWith(restock: map));
  }

  Future<void> _onSubmit(ShiftSubmit e, Emitter<ShiftState> emit) async {
    final shift = state.shift;
    if (shift == null) return;
    emit(state.copyWith(submitting: true));
    try {
      await repo.submitShift(
        cafeId: e.cafeId,
        shiftId: shift.id,
        closingSnapshot: state.closingSnapshot,
        cashCounted: state.cashCounted,
        expensesTotal: state.expensesTotal,
      );
      // nakon submit-a korisnik više nema OPEN smjenu → stream postaje null
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }

  Future<void> _onAccept(ShiftAccept e, Emitter<ShiftState> emit) async {
    await repo.acceptShift(cafeId: e.cafeId, shiftId: e.shiftId, acceptedByUid: e.acceptedByUid);
  }

  @override
  Future<void> close() {
    _activeSub?.cancel();
    return super.close();
  }
}
