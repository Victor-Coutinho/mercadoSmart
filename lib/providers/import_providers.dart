import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/gemini_shopping_list_interpreter.dart';
import '../services/ai/local_shopping_list_interpreter.dart';
import '../services/ai/remote_shopping_list_interpreter.dart';
import '../services/ai/shopping_list_interpreter.dart';
import '../services/image_capture_service.dart';
import '../services/import/photo_import_service.dart';
import '../services/import/remote_image_import_interpreter.dart';
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
  final localInterpreter = LocalShoppingListInterpreter();

  if (kIsWeb) {
    const endpoint = String.fromEnvironment(
      'GEMINI_PROXY_URL',
      defaultValue: '/api/interpret-shopping-list',
    );
    return RemoteShoppingListInterpreter(
      endpoint: Uri.base.resolve(endpoint),
      fallback: localInterpreter,
    );
  }

  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  const model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );

  if (apiKey.trim().isEmpty) {
    return localInterpreter;
  }

  return GeminiShoppingListInterpreter(
    apiKey: apiKey,
    model: model,
    fallback: localInterpreter,
  );
});

final photoImportServiceProvider = Provider<PhotoImportService>((ref) {
  const imageEndpoint = String.fromEnvironment(
    'GEMINI_IMAGE_PROXY_URL',
    defaultValue: '/api/interpret-shopping-image',
  );

  return PhotoImportService(
    imageCaptureService: ref.watch(imageCaptureServiceProvider),
    ocrService: ref.watch(ocrServiceProvider),
    interpreter: ref.watch(shoppingListInterpreterProvider),
    imageInterpreter: kIsWeb
        ? RemoteImageImportInterpreter(
            endpoint: Uri.base.resolve(imageEndpoint),
          )
        : null,
  );
});
