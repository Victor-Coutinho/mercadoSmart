import 'package:image_picker/image_picker.dart';

import '../../models/imported_shopping_item.dart';
import '../ai/shopping_list_interpreter.dart';
import '../image_capture_service.dart';
import '../ocr/ocr_service.dart';

class PhotoImportResult {
  const PhotoImportResult({
    required this.rawText,
    required this.items,
  });

  final String rawText;
  final List<ImportedShoppingItem> items;
}

class PhotoImportService {
  const PhotoImportService({
    required ImageCaptureService imageCaptureService,
    required OcrService ocrService,
    required ShoppingListInterpreter interpreter,
  })  : _imageCaptureService = imageCaptureService,
        _ocrService = ocrService,
        _interpreter = interpreter;

  final ImageCaptureService _imageCaptureService;
  final OcrService _ocrService;
  final ShoppingListInterpreter _interpreter;

  Future<PhotoImportResult?> import(ImageSource source) async {
    final image = await _imageCaptureService.pickImage(source);
    if (image == null) return null;

    final rawText = await _ocrService.extractText(image.path);
    if (rawText.trim().isEmpty) {
      return PhotoImportResult(rawText: rawText, items: const []);
    }

    final items = await _interpreter.interpret(rawText);
    return PhotoImportResult(rawText: rawText, items: items);
  }
}
