import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/drinks_repository.dart';
import '../../domain/drink.dart';
import 'drinks_event.dart';
import 'drinks_state.dart';

class DrinksBloc extends Bloc<DrinksEvent, DrinksState> {
  final DrinksRepository repo;
  final String cafeId;
  StreamSubscription<List<Drink>>? _sub;

  DrinksBloc({required this.repo, required this.cafeId}) : super(DrinksState.initial()) {
    // 1) Slušaj Firestore stream i pretvaraj u event
    _sub = repo.streamDrinks(cafeId).listen((list) {
      add(DrinksStreamUpdated(list));
    });

    // 2) Registruj handlere
    on<DrinksStreamUpdated>(_onStreamUpdated);
    on<DrinksSetQty>(_onSetQty);
    on<DrinksInc>(_onInc);
    on<DrinksDec>(_onDec);
    on<DrinksRevertOne>(_onRevertOne);
    on<DrinksResetAll>(_onResetAll);
    on<DrinksConfirm>(_onConfirm);
  }

  void _onStreamUpdated(DrinksStreamUpdated e, Emitter<DrinksState> emit) {
    // update server liste, zadrži lokalne izmjene
    emit(state.copyWith(drinks: e.drinks));
  }

  void _onSetQty(DrinksSetQty e, Emitter<DrinksState> emit) {
    final map = Map<String, int>.from(state.localQty);
    // pronađi original
    final maybe = state.drinks.where((d) => d.id == e.id);
    final original = maybe.isEmpty ? 0 : maybe.first.quantity;

    if (e.qty == original) {
      map.remove(e.id);
    } else {
      map[e.id] = e.qty;
    }
    emit(state.copyWith(localQty: map));
  }

  void _onInc(DrinksInc e, Emitter<DrinksState> emit) {
    final newQty = state.currentQty(e.id) + 1;
    add(DrinksSetQty(e.id, newQty));
  }

  void _onDec(DrinksDec e, Emitter<DrinksState> emit) {
    final cur = state.currentQty(e.id);
    if (cur > 0) add(DrinksSetQty(e.id, cur - 1));
  }

  void _onRevertOne(DrinksRevertOne e, Emitter<DrinksState> emit) {
    final map = Map<String, int>.from(state.localQty)..remove(e.id);
    emit(state.copyWith(localQty: map));
  }

  void _onResetAll(DrinksResetAll e, Emitter<DrinksState> emit) {
    emit(state.copyWith(localQty: const {}));
  }

  Future<void> _onConfirm(DrinksConfirm e, Emitter<DrinksState> emit) async {
    final deltas = state.deltas();
    if (deltas.isEmpty) return;
    emit(state.copyWith(saving: true));
    try {
      await repo.applyDeltas(
        cafeId: e.cafeId,
        deltas: deltas,
        updatedByUid: e.updatedByUid,
        updatedByName: e.updatedByName,
      );
      // očisti lokalne izmjene; nove server vrijednosti dolaze kroz stream
      emit(state.copyWith(localQty: const {}));
    } finally {
      emit(state.copyWith(saving: false));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
