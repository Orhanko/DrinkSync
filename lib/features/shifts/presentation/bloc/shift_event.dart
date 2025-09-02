abstract class ShiftEvent {
  const ShiftEvent();
}

class ShiftLoad extends ShiftEvent {
  final String cafeId;
  final String uid;
  const ShiftLoad(this.cafeId, this.uid);
}

class ShiftOpen extends ShiftEvent {
  final String cafeId;
  final String uid;
  final String name;
  const ShiftOpen(this.cafeId, this.uid, this.name);
}

class ShiftSetClosingQty extends ShiftEvent {
  final String drinkId;
  final int qty;
  const ShiftSetClosingQty(this.drinkId, this.qty);
}

class ShiftSetCash extends ShiftEvent {
  final int cashCounted; // feninga
  const ShiftSetCash(this.cashCounted);
}

class ShiftSetExpenses extends ShiftEvent {
  final int expensesTotal; // feninga
  const ShiftSetExpenses(this.expensesTotal);
}

class ShiftAddRestock extends ShiftEvent {
  final String drinkId;
  final int delta;
  final String byUid;
  final String byName;
  const ShiftAddRestock(this.drinkId, this.delta, this.byUid, this.byName);
}

class ShiftSubmit extends ShiftEvent {
  final String cafeId;
  const ShiftSubmit(this.cafeId);
}

class ShiftAccept extends ShiftEvent {
  final String cafeId;
  final String acceptedByUid;
  final String shiftId;
  const ShiftAccept(this.cafeId, this.acceptedByUid, this.shiftId);
}
