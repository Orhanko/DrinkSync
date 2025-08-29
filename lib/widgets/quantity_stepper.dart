import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onInc;
  final VoidCallback? onDec;

  const QuantityStepper({super.key, required this.qty, this.onInc, this.onDec});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: onDec,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
        ),
        Container(alignment: Alignment.center, width: 40, child: Text('$qty')),
        IconButton.filledTonal(
          onPressed: onInc,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
