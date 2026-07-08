import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shopping_list.dart';
import '../../providers/shopping_controller.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/text_input_dialog.dart';
import '../history/purchase_history_screen.dart';
import '../list_editor/list_editor_screen.dart';
import '../purchase/purchase_screen.dart';
import 'widgets/create_list_sheet.dart';
import 'widgets/shopping_list_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedIds.length} selecionada(s)')
            : const _BrandTitle(),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selectedIds.clear),
              )
            : null,
        actions: _selectionMode
            ? [
                if (_selectedIds.length == 1)
                  IconButton(
                    tooltip: 'Editar nome',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _renameSelected(context),
                  ),
                if (_selectedIds.length == 1)
                  IconButton(
                    tooltip: 'Duplicar',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: _duplicateSelected,
                  ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteSelected(context),
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Histórico',
                  icon: const Icon(Icons.history_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PurchaseHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
      ),
      body: state.lists.isEmpty
          ? const _EmptyHome()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: state.lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final list = state.lists[index];
                final market = state.marketById(list.marketId);
                final summary = state.summaryFor(list.id);
                final selected = _selectedIds.contains(list.id);
                return ShoppingListCard(
                  list: list,
                  marketName: market?.name ?? 'Mercado removido',
                  summary: summary,
                  selected: selected,
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(list.id);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PurchaseScreen(listId: list.id),
                      ),
                    );
                  },
                  onLongPress: () => _toggleSelection(list.id),
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListEditorScreen(listId: list.id),
                      ),
                    );
                  },
                  onDelete: () => _deleteSingle(context, list.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nova lista'),
        onPressed: _showCreateList,
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _showCreateList() async {
    final created = await showModalBottomSheet<ShoppingList>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateListSheet(),
    );
    if (!mounted || created == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListEditorScreen(listId: created.id)),
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Excluir listas?',
      message: 'Essa ação remove listas, seções e itens salvos.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await ref
        .read(shoppingControllerProvider.notifier)
        .deleteLists(_selectedIds);
    setState(_selectedIds.clear);
  }

  Future<void> _deleteSingle(BuildContext context, String id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Excluir lista?',
      message: 'Essa ação remove a lista, suas seções e seus itens salvos.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await ref.read(shoppingControllerProvider.notifier).deleteLists([id]);
    if (mounted) {
      setState(() => _selectedIds.remove(id));
    }
  }

  Future<void> _renameSelected(BuildContext context) async {
    final id = _selectedIds.single;
    final list = ref.read(shoppingControllerProvider).listById(id);
    if (list == null) {
      return;
    }

    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Editar nome',
        label: 'Nome da lista',
        confirmLabel: 'Salvar',
        initialValue: list.name,
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }
    await ref.read(shoppingControllerProvider.notifier).renameList(id, name);
    setState(_selectedIds.clear);
  }

  Future<void> _duplicateSelected() async {
    await ref
        .read(shoppingControllerProvider.notifier)
        .duplicateList(_selectedIds.single);
    setState(_selectedIds.clear);
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MercadoSmart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Listas rápidas por mercado',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma lista criada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie sua primeira lista para organizar itens por seção e acompanhar a compra no mercado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
