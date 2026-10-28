class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Please check your internet connection']);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Session expired. Please log in again'])
      : super(statusCode: 401);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Server error. Please try again later'])
      : super(statusCode: 500);
}
