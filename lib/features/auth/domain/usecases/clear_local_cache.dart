import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class ClearLocalCache implements UseCase<void, NoParams> {
  ClearLocalCache({
    required this.userRepository,
    required this.chatRepository,
  });

  final UserRepository userRepository;
  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    final usersResult = await userRepository.clearCache();
    final usersError = usersResult.fold((failure) => failure, (_) => null);
    if (usersError != null) {
      return Left(usersError);
    }
    return chatRepository.clearCache();
  }
}
