class ImageImportException implements Exception {
  const ImageImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
