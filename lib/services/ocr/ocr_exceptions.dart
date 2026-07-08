class OcrUnsupportedException implements Exception {
  const OcrUnsupportedException(this.message);

  final String message;

  @override
  String toString() => message;
}
