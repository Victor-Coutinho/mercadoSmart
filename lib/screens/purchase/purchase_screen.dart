import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_formatters.dart';
import '../../core/utils/section_visuals.dart';
import '../../models/shopping_item.dart';
import '../../providers/shopping_controller.dart';
import '../../widgets/common/text_input_dialog.dart';
import '../list_editor/list_editor_screen.dart';

class PurchaseScreen extends ConsumerWidget {
  const PurchaseScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingControllerProvider);
    final list = state.listById(listId);
    if (list == null) {
      return const Scaffold(body: Center(child: Text('Lista não encontrada.')));
    }

    final sections = state.sectionsForList(listId);
    final market = state.marketById(list.marketId);
    final summary = state.summaryFor(listId);
    final progress = summary.itemCount == 0
        ? 0.0
        : summary.purchasedCount / summary.itemCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          IconButton(
            tooltip: 'Salvar no histórico',
            icon: const Icon(Icons.history_outlined),
            onPressed: () => _saveToHistory(context, ref, list.name),
          ),
          IconButton(
            tooltip: 'Editar itens',
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListEditorScreen(listId: listId),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 116),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market?.name ?? 'Mercado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.purchasedCount}/${summary.itemCount} comprados · ${AppFormatters.currency(summary.total)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(value: progress, minHeight: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final section in sections)
            _PurchaseSection(
              title: section.name,
              items: state.itemsForSection(listId, section.id),
            ),
        ],
      ),
      bottomNavigationBar: _PurchaseTotalsBar(
        total: summary.total,
        purchasedTotal: summary.purchasedTotal,
        onSave: () => _saveToHistory(context, ref, list.name),
      ),
    );
  }

  Future<void> _saveToHistory(
    BuildContext context,
    WidgetRef ref,
    String defaultName,
  ) async {
    final historyName = await showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Salvar compra',
        label: 'Nome no histórico',
        confirmLabel: 'Salvar',
        confirmIcon: Icons.save_outlined,
        initialValue: defaultName,
      ),
    );
    if (historyName == null || historyName.isEmpty) {
      return;
    }

    await ref.read(shoppingControllerProvider.notifier).saveListToHistory(
          listId: listId,
          historyName: historyName,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra salva no histórico.')),
    );
  }
}

class _PurchaseSection extends ConsumerWidget {
  const _PurchaseSection({required this.title, required this.items});

  final String title;
  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: title, itemCount: items.length),
              const SizedBox(height: 10),
              for (final item in items)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: item.purchased ? 0.48 : 1,
                  child: CheckboxListTile(
                    value: item.purchased,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration:
                            item.purchased ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      '${AppFormatters.quantity(item.quantity)} un. · ${AppFormatters.currency(item.total)}',
                    ),
                    onChanged: (_) => ref
                        .read(shoppingControllerProvider.notifier)
                        .togglePurchased(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.itemCount});

  final String title;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final color = SectionVisuals.colorFor(context, title);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(SectionVisuals.iconFor(title), color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$itemCount item(ns) nesta seção',
                  style: TextStyle(color: color.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseTotalsBar extends StatelessWidget {
  const _PurchaseTotalsBar({
    required this.total,
    required this.purchasedTotal,
    required this.onSave,
  });

  final double total;
  final double purchasedTotal;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _TotalColumn(
                label: 'Total da compra',
                value: AppFormatters.currency(total),
              ),
            ),
            Expanded(
              child: _TotalColumn(
                label: 'Total comprado',
                value: AppFormatters.currency(purchasedTotal),
                highlighted: true,
              ),
            ),
            IconButton.filled(
              tooltip: 'Salvar no histórico',
              icon: const Icon(Icons.save_outlined),
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF0F172A);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
