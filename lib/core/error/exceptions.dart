class ServerException implements Exception {
  final String message;

  const ServerException([this.message = 'Server error']);
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error']);
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);
}

class RequestTimeoutException implements Exception {
  final String message;

  const RequestTimeoutException([
    this.message = 'Request timed out. Please try again.',
  ]);
}

class AuthException implements Exception {
  final String message;

  const AuthException([this.message = 'Authentication failed']);
}
