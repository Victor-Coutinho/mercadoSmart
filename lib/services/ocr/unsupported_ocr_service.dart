import 'ocr_exceptions.dart';
import 'ocr_service.dart';

OcrService createOcrService() => UnsupportedOcrService();

class UnsupportedOcrService implements OcrService {
  @override
  Future<String> extractText(String imagePath) {
    throw const OcrUnsupportedException(
      'OCR com ML Kit está disponível apenas em Android/iOS.',
    );
  }
}
