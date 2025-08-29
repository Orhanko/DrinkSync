class Drink {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool available;
  final int quantity;
  const Drink({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.available = true,
    this.quantity = 0,
  });
  Drink copyWith({int? quantity}) => Drink(
    id: id,
    name: name,
    price: price,
    category: category,
    available: available,
    quantity: quantity ?? this.quantity,
  );
}

const drinks = <Drink>[
  Drink(id: 'd1', name: 'Espresso', price: 2.00, category: 'Kafe', quantity: 1),
  Drink(id: 'd2', name: 'Cappuccino', price: 2.50, category: 'Kafe', quantity: 25),
  Drink(id: 'd3', name: 'Cedevita', price: 2.00, category: 'Sokovi', quantity: 29),
  Drink(id: 'd4', name: 'Coca-Cola', price: 2.50, category: 'Sokovi', quantity: 13),
  Drink(id: 'd5', name: 'Pivo 0.5', price: 3.50, category: 'Alkohol', quantity: 10),
  Drink(id: 'd6', name: 'Limunada', price: 2.50, category: 'Sokovi', quantity: 5),
  Drink(id: 'd7', name: 'Americano', price: 2.00, category: 'Kafe', quantity: 9),
];
