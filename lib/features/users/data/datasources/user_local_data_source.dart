import 'package:chat_app/features/users/data/models/user_model.dart';
import 'package:hive/hive.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUsers(List<UserModel> users);

  List<UserModel> getCachedUsers();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  UserLocalDataSourceImpl({required this.box});

  static const boxName = 'users_cache';
  static const _usersKey = 'users';

  final Box<dynamic> box;

  @override
  Future<void> cacheUsers(List<UserModel> users) {
    return box.put(_usersKey, users.map((user) => user.toJson()).toList());
  }

  @override
  List<UserModel> getCachedUsers() {
    final raw = box.get(_usersKey);
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map(UserModel.fromJson)
        .toList();
  }
}
