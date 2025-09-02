import 'package:flutter/material.dart';
import '../../../menu/domain/drink.dart';

class _DrinkOption {
  final String id;
  final String name;
  _DrinkOption(this.id, this.name);
}

class RestockResult {
  final String drinkId;
  final int delta;
  RestockResult(this.drinkId, this.delta);
}

class RestockDialog extends StatefulWidget {
  final List<Drink> drinks;
  const RestockDialog({super.key, required this.drinks});

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  String? _selectedId;
  int _delta = 1;

  @override
  Widget build(BuildContext context) {
    final options = widget.drinks.map((d) => _DrinkOption(d.id, d.name)).toList();
    return AlertDialog(
      title: const Text('Dopuna'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Artikal'),
            items: options.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(),
            onChanged: (v) => setState(() => _selectedId = v),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Količina (+)'),
            onChanged: (v) => _delta = int.tryParse(v) ?? 1,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(
          onPressed: (_selectedId == null || _delta <= 0)
              ? null
              : () => Navigator.pop(context, RestockResult(_selectedId!, _delta)),
          child: const Text('Snimi'),
        ),
      ],
    );
  }
}
