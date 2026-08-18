import 'package:chat_app/core/constants/app_timeouts.dart';
import 'package:chat_app/core/error/exceptions.dart';

Future<T> withTimeout<T>(Future<T> future) {
  return future.timeout(
    AppTimeouts.request,
    onTimeout: () => throw const RequestTimeoutException(),
  );
}
