import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/handover_repository.dart';
import 'handover_event.dart';
import 'handover_state.dart';

class HandoverBloc extends Bloc<HandoverEvent, HandoverState> {
  final HandoverRepository repo;
  final FirebaseAuth _auth;

  HandoverBloc({required this.repo, FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      super(HandoverState.initial()) {
    on<HandoverInit>(_onInit);
    on<HandoverStart>(_onStart);
    on<HandoverCashChanged>(_onCashChanged);
    on<HandoverExpensesChanged>(_onExpensesChanged);
    on<HandoverClose>(_onClose);
  }

  /* INIT: provjeri ima li otvorene sesije za ovog korisnika */
  Future<void> _onInit(HandoverInit e, Emitter<HandoverState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Niste prijavljeni.');

      final sessionId = await repo.getActiveSessionId(cafeId: e.cafeId, uid: uid);
      emit(state.copyWith(loading: false, activeSessionId: sessionId, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  /* START: otvori smjenu i snimi openingSnapshot */
  Future<void> _onStart(HandoverStart e, Emitter<HandoverState> emit) async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Niste prijavljeni.');

      final sessionId = await repo.startSession(cafeId: e.cafeId, uid: uid, openedByName: e.openedByName);

      emit(
        state.copyWith(
          loading: false,
          activeSessionId: sessionId,
          // reset lokalnih polja pri otvaranju
          cashCents: 0,
          expensesCents: 0,
          error: null,
        ),
      );
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  /* LOKALNI UNOSI: ažuriraj state bez IO-a */
  void _onCashChanged(HandoverCashChanged e, Emitter<HandoverState> emit) {
    emit(state.copyWith(cashCents: e.cashCents, error: null));
  }

  void _onExpensesChanged(HandoverExpensesChanged e, Emitter<HandoverState> emit) {
    emit(state.copyWith(expensesCents: e.expensesCents, error: null));
  }

  /* CLOSE: zatvori smjenu, snimi closingSnapshot + unose, pa resetuj UI */
  Future<void> _onClose(HandoverClose e, Emitter<HandoverState> emit) async {
    if (state.loading) return;
    if (state.activeSessionId == null) {
      emit(state.copyWith(error: 'Nema aktivne smjene za zatvoriti.'));
      return;
    }

    emit(state.copyWith(loading: true, error: null));
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Niste prijavljeni.');

      await repo.closeSession(
        cafeId: e.cafeId,
        sessionId: state.activeSessionId!,
        uid: uid,
        closedByName: e.closedByName,
        cashCount: state.cashCents,
        expenses: state.expensesCents,
      );

      // Nakon uspješnog zatvaranja: nema aktivne sesije i očisti inpute
      emit(state.copyWith(loading: false, activeSessionId: null, cashCents: 0, expensesCents: 0, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}
