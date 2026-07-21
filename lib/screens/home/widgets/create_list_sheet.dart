import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/imported_shopping_item.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/shopping_controller.dart';
import '../../../services/import/image_import_exception.dart';
import '../../../services/ocr/ocr_exceptions.dart';
import '../../import_review/import_review_screen.dart';

class CreateListSheet extends ConsumerStatefulWidget {
  const CreateListSheet({super.key});

  @override
  ConsumerState<CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends ConsumerState<CreateListSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _marketController = TextEditingController();
  String? _marketId;
  bool _creatingMarket = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _marketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markets = ref.watch(shoppingControllerProvider).markets;
    _marketId ??= markets.isNotEmpty ? markets.first.id : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Nova lista',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome da lista'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Existente'),
                    icon: Icon(Icons.store_outlined)),
                ButtonSegment(
                    value: true,
                    label: Text('Novo'),
                    icon: Icon(Icons.add_business_outlined)),
              ],
              selected: {_creatingMarket},
              onSelectionChanged: (value) =>
                  setState(() => _creatingMarket = value.first),
            ),
            const SizedBox(height: 12),
            if (_creatingMarket)
              TextFormField(
                controller: _marketController,
                decoration: const InputDecoration(labelText: 'Nome do mercado'),
                validator: (value) =>
                    _creatingMarket && (value ?? '').trim().isEmpty
                        ? 'Informe o mercado'
                        : null,
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _marketId,
                decoration: const InputDecoration(labelText: 'Mercado'),
                items: markets
                    .map((market) => DropdownMenuItem(
                        value: market.id, child: Text(market.name)))
                    .toList(),
                onChanged: (value) => setState(() => _marketId = value),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Criar lista vazia'),
                onPressed: _isImporting ? null : _submit,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: const Text('Criar importando foto'),
                onPressed: _isImporting ? null : _submitWithImport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final list = await ref.read(shoppingControllerProvider.notifier).createList(
          name: _nameController.text,
          marketId: _marketId ?? '',
          newMarketName: _creatingMarket ? _marketController.text : null,
        );
    if (mounted) {
      Navigator.pop<ShoppingList>(context, list);
    }
  }

  Future<void> _submitWithImport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
            sections: const [],
          ),
        ),
      );

      if (!mounted || reviewedItems == null || reviewedItems.isEmpty) return;

      final list =
          await ref.read(shoppingControllerProvider.notifier).createList(
                name: _nameController.text,
                marketId: _marketId ?? '',
                newMarketName: _creatingMarket ? _marketController.text : null,
              );
      await ref.read(shoppingControllerProvider.notifier).importItems(
            listId: list.id,
            items: reviewedItems,
          );

      if (mounted) {
        Navigator.pop<ShoppingList>(context, list);
      }
    } on OcrUnsupportedException catch (error) {
      _showImportError(error.message);
    } on ImageImportException catch (error) {
      _showImportError(error.message);
    } catch (_) {
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
}
