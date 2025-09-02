import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/drinks_repository.dart';
import '../../domain/drink.dart';
import 'drinks_event.dart';
import 'drinks_state.dart';

/// BLoC za Menu:
/// - sluša stream pića
/// - vodi lokalne izmjene količina
/// - potvrđuje delta promjene + loguje u /logs
class DrinksBloc extends Bloc<DrinksEvent, DrinksState> {
  final DrinksRepository repo;
  final String cafeId;
  StreamSubscription<List<Drink>>? _sub;

  DrinksBloc({required this.repo, required this.cafeId}) : super(DrinksState.initial()) {
    // Stream od Firestore-a
    _sub = repo.streamDrinks(cafeId).listen((list) => add(DrinksStreamUpdated(list)));

    on<DrinksStreamUpdated>(_onStreamUpdated);
    on<DrinksSetQty>(_onSetQty);
    on<DrinksInc>(_onInc);
    on<DrinksDec>(_onDec);
    on<DrinksRevertOne>(_onRevertOne);
    on<DrinksResetAll>(_onResetAll);
    on<DrinksConfirm>(_onConfirm);
  }

  void _onStreamUpdated(DrinksStreamUpdated e, Emitter<DrinksState> emit) {
    emit(state.copyWith(drinks: e.drinks));
  }

  void _onSetQty(DrinksSetQty e, Emitter<DrinksState> emit) {
    final map = Map<String, int>.from(state.localQty);

    final originalQty = state.drinks
        .firstWhere(
          (d) => d.id == e.id,
          orElse: () => Drink(id: e.id, name: '', quantity: 0),
        )
        .quantity;

    if (e.qty == originalQty) {
      map.remove(e.id);
    } else {
      map[e.id] = e.qty;
    }
    emit(state.copyWith(localQty: map));
  }

  void _onInc(DrinksInc e, Emitter<DrinksState> emit) {
    add(DrinksSetQty(e.id, state.currentQty(e.id) + 1));
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
    if (deltas.isEmpty || state.saving) return;

    emit(state.copyWith(saving: true));
    try {
      await repo.applyDeltas(
        cafeId: e.cafeId,
        deltas: deltas,
        updatedByUid: e.updatedByUid,
        updatedByName: e.updatedByName,
      );
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
