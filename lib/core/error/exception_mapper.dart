import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/core/error/failures.dart';

Failure? failureFromException(Object error) {
  if (error is RequestTimeoutException) {
    return TimeoutFailure(error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is ServerException) {
    return ServerFailure(error.message);
  }
  if (error is AuthException) {
    return AuthFailure(error.message);
  }
  if (error is CacheException) {
    return CacheFailure(error.message);
  }
  return null;
}
