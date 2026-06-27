class BahaApiException implements Exception {
  const BahaApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'BahaApiException($statusCode): $message';
}
