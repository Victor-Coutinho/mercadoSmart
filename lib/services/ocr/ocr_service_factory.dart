import 'unsupported_ocr_service.dart'
    if (dart.library.io) 'mlkit_ocr_service.dart';

import 'ocr_service.dart';

OcrService buildOcrService() => createOcrService();
