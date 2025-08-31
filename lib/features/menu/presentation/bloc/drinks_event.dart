import '../../domain/drink.dart';

abstract class DrinksEvent {
  const DrinksEvent();
}

class DrinksStreamUpdated extends DrinksEvent {
  final List<Drink> drinks;
  const DrinksStreamUpdated(this.drinks);
}

class DrinksSetQty extends DrinksEvent {
  final String id;
  final int qty;
  const DrinksSetQty(this.id, this.qty);
}

class DrinksInc extends DrinksEvent {
  final String id;
  const DrinksInc(this.id);
}

class DrinksDec extends DrinksEvent {
  final String id;
  const DrinksDec(this.id);
}

class DrinksRevertOne extends DrinksEvent {
  final String id;
  const DrinksRevertOne(this.id);
}

class DrinksResetAll extends DrinksEvent {
  const DrinksResetAll();
}

class DrinksConfirm extends DrinksEvent {
  final String cafeId;
  final String? updatedByUid;
  final String? updatedByName;
  const DrinksConfirm({required this.cafeId, required this.updatedByUid, required this.updatedByName});
}
