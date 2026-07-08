import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

OcrService createOcrService() => MlKitOcrService();

class MlKitOcrService implements OcrService {
  @override
  Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(image);
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
