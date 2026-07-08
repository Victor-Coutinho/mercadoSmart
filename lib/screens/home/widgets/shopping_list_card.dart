import 'package:flutter/material.dart';

import '../../../core/utils/app_formatters.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/app_state.dart';

class ShoppingListCard extends StatelessWidget {
  const ShoppingListCard({
    super.key,
    required this.list,
    required this.marketName,
    required this.summary,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingList list;
  final String marketName;
  final ShoppingListSummary summary;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = summary.itemCount == 0
        ? 0.0
        : summary.purchasedCount / summary.itemCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$marketName · ${AppFormatters.date(list.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar lista',
                      icon: const Icon(Icons.edit_note_outlined),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: 'Excluir lista',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: Color(0xFF164E63)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Metric(
                        icon: Icons.inventory_2_outlined,
                        label: '${summary.itemCount} itens'),
                    const SizedBox(width: 12),
                    _Metric(
                      icon: Icons.check_circle_outline,
                      label: '${summary.purchasedCount} comprados',
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.currency(summary.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
