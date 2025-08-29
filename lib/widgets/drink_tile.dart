import 'package:flutter/material.dart';

class DrinkTile extends StatefulWidget {
  final String drinkId;
  final String name;
  final int quantity; // initial quantity from parent/stream
  final int originalQuantity; // server quantity to diff against
  final int syncToken;
  final ValueChanged<int> onChanged; // notify parent about new desired qty
  final VoidCallback? onRevert; // optional per-item revert callback (parent can clean maps)
  final String? subtitle;

  const DrinkTile({
    super.key,
    required this.drinkId,
    required this.name,
    required this.quantity,
    required this.originalQuantity,
    required this.syncToken,
    required this.onChanged,
    this.onRevert,
    this.subtitle,
  });

  @override
  State<DrinkTile> createState() => _DrinkTileState();
}

class _DrinkTileState extends State<DrinkTile> with AutomaticKeepAliveClientMixin {
  late int _qty; // local, lagano re-rendera samo ovaj tile

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
  }

  @override
  void didUpdateWidget(covariant DrinkTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ako se promijenio syncToken (reset all ili confirm), natjeraj na parent quantity
    if (widget.syncToken != oldWidget.syncToken) {
      setState(() => _qty = widget.quantity);
      return;
    }
    // Normalni sync kad stigne nova vrijednost sa servera i nismo lokalno mijenjali
    if (_qty == oldWidget.quantity && widget.quantity != oldWidget.quantity) {
      setState(() => _qty = widget.quantity);
    }
  }

  void _inc() {
    setState(() => _qty += 1);
    widget.onChanged(_qty);
  }

  void _dec() {
    if (_qty <= 0) return;
    setState(() => _qty -= 1);
    widget.onChanged(_qty);
  }

  void _revertLocal() {
    setState(() => _qty = widget.originalQuantity);
    widget.onChanged(_qty);
    widget.onRevert?.call();
  }

  bool get _isModified => _qty != widget.originalQuantity;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isModified
            ? cs.primaryContainer.withOpacity(0.45)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isModified ? cs.primary : cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: Theme.of(context).textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.subtitle!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isModified && widget.onRevert != null)
                IconButton(
                  tooltip: 'Vrati na ${widget.originalQuantity}',
                  visualDensity: VisualDensity.compact,
                  onPressed: _revertLocal,
                  icon: const Icon(Icons.undo),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: _qty > 0 ? _dec : null),
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: Text('$_qty', key: ValueKey(_qty), style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: _inc),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
