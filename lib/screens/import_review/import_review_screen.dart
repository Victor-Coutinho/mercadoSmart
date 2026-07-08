import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/default_sections.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/imported_shopping_item.dart';
import '../../models/shopping_section.dart';

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.initialItems,
    required this.rawText,
    required this.sections,
  });

  final List<ImportedShoppingItem> initialItems;
  final String rawText;
  final List<ShoppingSection> sections;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late final List<_ReviewItem> _items;
  var _nextId = 0;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems
        .map((item) => _ReviewItem(id: _nextId++, item: item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sectionNames = _sectionNames;
    final total = _items.fold<double>(
      0,
      (sum, entry) => sum + entry.item.quantity * entry.item.unitPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar importação'),
        actions: [
          IconButton(
            tooltip: 'Adicionar item',
            icon: const Icon(Icons.add),
            onPressed: _addBlankItem,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        children: [
          _ImportSummaryCard(
            itemCount: _items.length,
            total: total,
          ),
          const SizedBox(height: 12),
          if (widget.rawText.trim().isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Texto reconhecido'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(widget.rawText),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const _EmptyImportReview()
          else
            for (var index = 0; index < _items.length; index++) ...[
              _ImportedItemCard(
                key: ValueKey('import-item-${_items[index].id}'),
                item: _items[index].item,
                sectionNames: sectionNames,
                onChanged: (item) => _updateItem(index, item),
                onRemove: () => _removeItem(index),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text('Adicionar ${_items.length} item(ns)'),
            onPressed: _items.isEmpty
                ? null
                : () {
                    final validItems = _items
                        .map((entry) => entry.item)
                        .where((item) => item.name.trim().isNotEmpty)
                        .toList();
                    Navigator.pop(context, validItems);
                  },
          ),
        ),
      ),
    );
  }

  List<String> get _sectionNames {
    final values = <String>{
      ...DefaultSections.names,
      ...widget.sections.map((section) => section.name),
      ..._items.map((entry) => entry.item.sectionName),
    };
    return values.where((value) => value.trim().isNotEmpty).toList()..sort();
  }

  void _addBlankItem() {
    setState(() {
      _items.add(
        _ReviewItem(
          id: _nextId++,
          item: const ImportedShoppingItem(
            name: '',
            quantity: 1,
            unitPrice: 0,
            sectionName: 'Mercearia',
          ),
        ),
      );
    });
  }

  void _updateItem(int index, ImportedShoppingItem item) {
    setState(() => _items[index] = _items[index].copyWith(item: item));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }
}

class _ImportSummaryCard extends StatelessWidget {
  const _ImportSummaryCard({
    required this.itemCount,
    required this.total,
  });

  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF164E63), Color(0xFF0891B2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.document_scanner_outlined,
              color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revise antes de salvar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900),
                ),
                Text(
                  '$itemCount itens reconhecidos · ${AppFormatters.currency(total)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportedItemCard extends StatelessWidget {
  const _ImportedItemCard({
    super.key,
    required this.item,
    required this.sectionNames,
    required this.onChanged,
    required this.onRemove,
  });

  final ImportedShoppingItem item;
  final List<String> sectionNames;
  final ValueChanged<ImportedShoppingItem> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedSection = sectionNames.contains(item.sectionName)
        ? item.sectionName
        : sectionNames.firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(labelText: 'Item'),
                    onChanged: (value) => onChanged(item.copyWith(name: value)),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: AppFormatters.quantity(item.quantity),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Qtd.'),
                    onChanged: (value) => onChanged(
                      item.copyWith(
                        quantity:
                            double.tryParse(value.replaceAll(',', '.')) ?? 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice == 0
                        ? ''
                        : item.unitPrice.toStringAsFixed(2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Preço'),
                    onChanged: (value) => onChanged(
                      item.copyWith(
                        unitPrice:
                            double.tryParse(value.replaceAll(',', '.')) ?? 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedSection,
              decoration: const InputDecoration(labelText: 'Seção'),
              items: sectionNames
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(item.copyWith(sectionName: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyImportReview extends StatelessWidget {
  const _EmptyImportReview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Nenhum item reconhecido',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Você pode adicionar itens manualmente pelo botão superior.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({required this.id, required this.item});

  final int id;
  final ImportedShoppingItem item;

  _ReviewItem copyWith({ImportedShoppingItem? item}) {
    return _ReviewItem(id: id, item: item ?? this.item);
  }
}
