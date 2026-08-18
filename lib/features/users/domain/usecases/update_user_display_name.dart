import 'package:chat_app/core/error/failures.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/users/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateUserDisplayName
    implements UseCase<void, UpdateUserDisplayNameParams> {
  UpdateUserDisplayName(this.repository);

  final UserRepository repository;

  @override
  Future<Either<Failure, void>> call(UpdateUserDisplayNameParams params) {
    return repository.updateDisplayName(
      uid: params.uid,
      displayName: params.displayName,
    );
  }
}

class UpdateUserDisplayNameParams extends Equatable {
  const UpdateUserDisplayNameParams({
    required this.uid,
    required this.displayName,
  });

  final String uid;
  final String displayName;

  @override
  List<Object?> get props => [uid, displayName];
}
