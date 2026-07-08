import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/local_shopping_list_interpreter.dart';
import '../services/ai/shopping_list_interpreter.dart';
import '../services/image_capture_service.dart';
import '../services/import/photo_import_service.dart';
import '../services/ocr/ocr_service.dart';
import '../services/ocr/ocr_service_factory.dart';

final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) {
  return ImageCaptureService();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return buildOcrService();
});

final shoppingListInterpreterProvider =
    Provider<ShoppingListInterpreter>((ref) {
  return LocalShoppingListInterpreter();
});

final photoImportServiceProvider = Provider<PhotoImportService>((ref) {
  return PhotoImportService(
    imageCaptureService: ref.watch(imageCaptureServiceProvider),
    ocrService: ref.watch(ocrServiceProvider),
    interpreter: ref.watch(shoppingListInterpreterProvider),
  );
});
