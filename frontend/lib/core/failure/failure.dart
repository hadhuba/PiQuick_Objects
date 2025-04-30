class AppFailure {
  final String message;
  final int? statusCode;
  AppFailure([this.message = 'Sorry, an unexpected error occurred', this.statusCode]);

  @override
  String toString() => 'AppFailure(message: $message, statusCode: $statusCode)';
}
