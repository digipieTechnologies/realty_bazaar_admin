class ApiException implements Exception {
  final String message;
  final int? code;
  final dynamic data;

  const ApiException(this.message, {this.code, this.data});

  @override
  String toString() => 'ApiException(code: $code, message: $message, data: $data)';
}
