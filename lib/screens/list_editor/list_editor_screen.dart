import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_formatters.dart';
import '../../models/imported_shopping_item.dart';
import '../../models/shopping_item.dart';
import '../../models/shopping_section.dart';
import '../../providers/import_providers.dart';
import '../../providers/shopping_controller.dart';
import '../../services/import/image_import_exception.dart';
import '../../services/ocr/ocr_exceptions.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/text_input_dialog.dart';
import '../import_review/import_review_screen.dart';
import '../purchase/purchase_screen.dart';

class ListEditorScreen extends ConsumerStatefulWidget {
  const ListEditorScreen({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<ListEditorScreen> createState() => _ListEditorScreenState();
}

class _ListEditorScreenState extends ConsumerState<ListEditorScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _nameFocus = FocusNode();
  String? _sectionId;
  bool _isImporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingControllerProvider);
    final list = state.listById(widget.listId);
    if (list == null) {
      return const Scaffold(body: Center(child: Text('Lista não encontrada.')));
    }

    final market = state.marketById(list.marketId);
    final sections = state.sectionsForList(widget.listId);
    final summary = state.summaryFor(widget.listId);
    _sectionId ??= sections.isNotEmpty ? sections.first.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          IconButton(
            tooltip: 'Importar por foto',
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined),
            onPressed: _isImporting ? null : () => _startPhotoImport(sections),
          ),
          IconButton(
            tooltip: 'Seções',
            icon: const Icon(Icons.view_week_outlined),
            onPressed: () => _showSectionsSheet(context),
          ),
          IconButton(
            tooltip: 'Iniciar compra',
            icon: const Icon(Icons.playlist_add_check_circle_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => PurchaseScreen(listId: widget.listId)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SummaryHeader(
            marketName: market?.name ?? 'Mercado removido',
            itemCount: summary.itemCount,
            total: summary.total,
          ),
          const SizedBox(height: 14),
          _ItemForm(
            nameController: _nameController,
            quantityController: _quantityController,
            priceController: _priceController,
            nameFocus: _nameFocus,
            sections: sections,
            sectionId: _sectionId,
            onSectionChanged: (value) => setState(() => _sectionId = value),
            onAdd: _addItem,
            onImport: _isImporting ? null : () => _startPhotoImport(sections),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            _EditorSectionGroup(
              section: section,
              items: state.itemsForSection(widget.listId, section.id),
              onEditItem: _editItem,
              onDeleteItem: (item) => ref
                  .read(shoppingControllerProvider.notifier)
                  .deleteItem(item.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _sectionId == null) {
      return;
    }
    final quantity =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

    await ref.read(shoppingControllerProvider.notifier).addItem(
          listId: widget.listId,
          sectionId: _sectionId!,
          name: name,
          quantity: quantity <= 0 ? 1 : quantity,
          unitPrice: price < 0 ? 0 : price,
        );

    _nameController.clear();
    _quantityController.text = '1';
    _priceController.clear();
    _nameFocus.requestFocus();
  }

  Future<void> _startPhotoImport(List<ShoppingSection> sections) async {
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    setState(() => _isImporting = true);
    try {
      final result = await ref.read(photoImportServiceProvider).import(source);
      if (!mounted || result == null) return;

      final reviewedItems =
          await Navigator.of(context).push<List<ImportedShoppingItem>>(
        MaterialPageRoute(
          builder: (_) => ImportReviewScreen(
            initialItems: result.items,
            rawText: result.rawText,
            sections: sections,
          ),
        ),
      );

      if (!mounted || reviewedItems == null || reviewedItems.isEmpty) return;
      await ref.read(shoppingControllerProvider.notifier).importItems(
            listId: widget.listId,
            items: reviewedItems,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reviewedItems.length} item(ns) importados.'),
        ),
      );
    } on OcrUnsupportedException catch (error) {
      _showImportError(error.message);
    } on ImageImportException catch (error) {
      _showImportError(error.message);
    } catch (error) {
      _showImportError('Não foi possível importar a imagem. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                subtitle: const Text('Abrir a câmera do celular'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Escolher imagem'),
                subtitle: const Text('Usar uma foto da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editItem(ShoppingItem item) async {
    final sections =
        ref.read(shoppingControllerProvider).sectionsForList(widget.listId);

    final updated = await showModalBottomSheet<ShoppingItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditItemSheet(
        item: item,
        sections: sections,
      ),
    );

    if (updated != null && updated.name.isNotEmpty) {
      await ref.read(shoppingControllerProvider.notifier).updateItem(updated);
    }
  }

  Future<void> _showSectionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SectionsSheet(listId: widget.listId),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.marketName,
    required this.itemCount,
    required this.total,
  });

  final String marketName;
  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF164E63), Color(0xFF0891B2)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(marketName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                Text(
                  '$itemCount itens · ${AppFormatters.currency(total)} previstos',
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

class _ItemForm extends StatelessWidget {
  const _ItemForm({
    required this.nameController,
    required this.quantityController,
    required this.priceController,
    required this.nameFocus,
    required this.sections,
    required this.sectionId,
    required this.onSectionChanged,
    required this.onAdd,
    required this.onImport,
  });

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final FocusNode nameFocus;
  final List<ShoppingSection> sections;
  final String? sectionId;
  final ValueChanged<String?> onSectionChanged;
  final VoidCallback onAdd;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              focusNode: nameFocus,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome do item',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onAdd(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                    ],
                    decoration: const InputDecoration(labelText: 'Qtd.'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
                    ],
                    decoration: const InputDecoration(labelText: 'Preço'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: sectionId,
              decoration: const InputDecoration(labelText: 'Seção'),
              items: sections
                  .map((section) => DropdownMenuItem(
                      value: section.id, child: Text(section.name)))
                  .toList(),
              onChanged: onSectionChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
                onPressed: onAdd,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Importar por foto'),
                onPressed: onImport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSectionGroup extends StatelessWidget {
  const _EditorSectionGroup({
    required this.section,
    required this.items,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final ShoppingSection section;
  final List<ShoppingItem> items;
  final ValueChanged<ShoppingItem> onEditItem;
  final ValueChanged<ShoppingItem> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.name.toUpperCase(),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${AppFormatters.quantity(item.quantity)} un. · ${AppFormatters.currency(item.total)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => onEditItem(item),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDeleteItem(item),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionsSheet extends ConsumerWidget {
  const _SectionsSheet({required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections =
        ref.watch(shoppingControllerProvider).sectionsForList(listId);
    final controller = ref.read(shoppingControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Seções da lista',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                tooltip: 'Nova seção',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _promptSectionName(context, ref, listId: listId),
              ),
            ],
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: sections.length,
              onReorder: (oldIndex, newIndex) =>
                  controller.reorderSection(listId, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final section = sections[index];
                return ListTile(
                  key: ValueKey(section.id),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(section.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Subir',
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: () => controller.moveSection(section, -1),
                      ),
                      IconButton(
                        tooltip: 'Descer',
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => controller.moveSection(section, 1),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'rename') {
                            await _promptSectionName(context, ref,
                                section: section);
                          } else if (value == 'delete') {
                            final confirmed = await ConfirmationDialog.show(
                              context,
                              title: 'Excluir seção?',
                              message:
                                  'Os itens dessa seção também serão removidos.',
                              confirmLabel: 'Excluir',
                              destructive: true,
                            );
                            if (confirmed) {
                              await controller.deleteSection(section);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'rename', child: Text('Renomear')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Excluir')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSectionName(
    BuildContext context,
    WidgetRef ref, {
    String? listId,
    ShoppingSection? section,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: section == null ? 'Nova seção' : 'Renomear seção',
        label: 'Nome',
        confirmLabel: 'Salvar',
        initialValue: section?.name ?? '',
      ),
    );
    if (name == null || name.isEmpty) {
      return;
    }

    final notifier = ref.read(shoppingControllerProvider.notifier);
    if (section == null) {
      await notifier.addSection(listId!, name);
    } else {
      await notifier.renameSection(section.id, name);
    }
  }
}

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({
    required this.item,
    required this.sections,
  });

  final ShoppingItem item;
  final List<ShoppingSection> sections;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late String _sectionId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _priceController =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
    _sectionId = widget.item.sectionId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Item'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qtd.'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Preço'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _sectionId,
            decoration: const InputDecoration(labelText: 'Seção'),
            items: widget.sections
                .map(
                  (section) => DropdownMenuItem(
                    value: section.id,
                    child: Text(section.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sectionId = value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  widget.item.copyWith(
                    name: _nameController.text.trim(),
                    quantity: double.tryParse(
                          _quantityController.text.replaceAll(',', '.'),
                        ) ??
                        1,
                    unitPrice: double.tryParse(
                          _priceController.text.replaceAll(',', '.'),
                        ) ??
                        0,
                    sectionId: _sectionId,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
