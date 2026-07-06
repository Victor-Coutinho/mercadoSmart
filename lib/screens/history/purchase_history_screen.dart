import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_formatters.dart';
import '../../models/purchase_history.dart';
import '../../providers/shopping_controller.dart';
import '../list_editor/list_editor_screen.dart';

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  String? _marketId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingControllerProvider);
    if (state.markets.isNotEmpty &&
        (_marketId == null || state.marketById(_marketId!) == null)) {
      _marketId = state.markets.first.id;
    }

    final histories = _marketId == null
        ? <PurchaseHistory>[]
        : state.historiesForMarket(_marketId!);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de compras')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _marketId,
              decoration: const InputDecoration(
                labelText: 'Mercado',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              items: state.markets
                  .map(
                    (market) => DropdownMenuItem(
                      value: market.id,
                      child: Text(market.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _marketId = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: histories.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      itemCount: histories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final history = histories[index];
                        return _HistoryCard(
                          history: history,
                          onTap: () => _showHistoryDetails(context, history),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistoryDetails(
    BuildContext context,
    PurchaseHistory history,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _HistoryDetailsSheet(
        history: history,
        onReuse: () => _reuseHistory(context, history),
      ),
    );
  }

  Future<void> _reuseHistory(
    BuildContext sheetContext,
    PurchaseHistory history,
  ) async {
    final nameController = TextEditingController(text: '${history.name} nova');
    final listName = await showDialog<String>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Reutilizar compra'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da nova lista'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Criar lista'),
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (listName == null || listName.isEmpty) {
      return;
    }

    final list =
        await ref.read(shoppingControllerProvider.notifier).reuseHistory(
              historyId: history.id,
              listName: listName,
            );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListEditorScreen(listId: list.id)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.onTap});

  final PurchaseHistory history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.dateTime(history.savedAt)} · ${history.items.length} itens',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.currency(history.total),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDetailsSheet extends StatelessWidget {
  const _HistoryDetailsSheet({
    required this.history,
    required this.onReuse,
  });

  final PurchaseHistory history;
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    final sections = [...history.sections]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${history.marketName} · ${AppFormatters.dateTime(history.savedAt)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Reutilizar'),
                onPressed: onReuse,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Valor total: ${AppFormatters.currency(history.total)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                for (final section in sections)
                  _HistorySectionBlock(
                    section: section,
                    items: history.items
                        .where(
                          (item) =>
                              item.sectionSnapshotId == section.snapshotId,
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySectionBlock extends StatelessWidget {
  const _HistorySectionBlock({required this.section, required this.items});

  final PurchaseHistorySection section;
  final List<PurchaseHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.name.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    '${AppFormatters.quantity(item.quantity)} un. · ${AppFormatters.currency(item.total)}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 68, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma compra salva',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ao finalizar uma compra, salve no histórico para reutilizar depois.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
