import 'package:flutter/material.dart';

class SummaryBottomBar extends StatelessWidget {
  final int itemsCount;
  final double total;

  const SummaryBottomBar({super.key, required this.itemsCount, required this.total});

  @override
  Widget build(BuildContext context) {
    if (itemsCount == 0) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$itemsCount artikala • ${total.toStringAsFixed(2)} KM',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('Nastavi'),
            ),
          ],
        ),
      ),
    );
  }
}
