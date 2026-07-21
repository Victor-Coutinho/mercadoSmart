import 'package:image_picker/image_picker.dart';

import '../../models/imported_shopping_item.dart';

class ImageImportInterpretation {
  const ImageImportInterpretation({
    required this.rawText,
    required this.items,
  });

  final String rawText;
  final List<ImportedShoppingItem> items;
}

abstract class ImageImportInterpreter {
  Future<ImageImportInterpretation> interpretImage(XFile image);
}
