import '../../models/imported_shopping_item.dart';
import 'shopping_list_interpreter.dart';

class GeminiShoppingListInterpreter implements ShoppingListInterpreter {
  const GeminiShoppingListInterpreter({required this.apiKey});

  final String apiKey;

  @override
  Future<List<ImportedShoppingItem>> interpret(String rawText) {
    throw UnimplementedError(
      'Integração Gemini preparada para futura troca de provedor. '
      'Use este serviço para enviar o texto OCR e receber JSON estruturado.',
    );
  }
}
