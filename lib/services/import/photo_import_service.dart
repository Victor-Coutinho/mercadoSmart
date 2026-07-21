import 'package:image_picker/image_picker.dart';

import '../../models/imported_shopping_item.dart';
import '../ai/shopping_list_interpreter.dart';
import '../image_capture_service.dart';
import '../ocr/ocr_service.dart';
import 'image_import_exception.dart';
import 'image_import_interpreter.dart';

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
    ImageImportInterpreter? imageInterpreter,
  })  : _imageCaptureService = imageCaptureService,
        _ocrService = ocrService,
        _interpreter = interpreter,
        _imageInterpreter = imageInterpreter;

  final ImageCaptureService _imageCaptureService;
  final OcrService _ocrService;
  final ShoppingListInterpreter _interpreter;
  final ImageImportInterpreter? _imageInterpreter;

  Future<PhotoImportResult?> import(ImageSource source) async {
    final image = await _imageCaptureService.pickImage(source);
    if (image == null) return null;

    final imageInterpreter = _imageInterpreter;
    if (imageInterpreter != null) {
      final result = await imageInterpreter.interpretImage(image);
      if (result.rawText.trim().isEmpty && result.items.isEmpty) {
        throw const ImageImportException(
          'Nao foi possivel reconhecer itens nessa imagem. Tente uma foto mais nitida ou recorte apenas a lista.',
        );
      }
      return PhotoImportResult(rawText: result.rawText, items: result.items);
    }

    final rawText = await _ocrService.extractText(image.path);
    if (rawText.trim().isEmpty) {
      return PhotoImportResult(rawText: rawText, items: const []);
    }

    final items = await _interpreter.interpret(rawText);
    return PhotoImportResult(rawText: rawText, items: items);
  }
}
