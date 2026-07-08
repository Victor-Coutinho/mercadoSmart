import 'package:image_picker/image_picker.dart';

class ImageCaptureService {
  ImageCaptureService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickImage(ImageSource source) {
    return _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
  }
}
