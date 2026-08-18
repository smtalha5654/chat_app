import 'package:chat_app/features/users/data/models/user_model.dart';
import 'package:hive/hive.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUsers(List<UserModel> users);

  List<UserModel> getCachedUsers();

  Future<void> clearCache();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  UserLocalDataSourceImpl({required this.box});

  static const boxName = 'users_cache';
  static const _cacheKey = 'users';
  static const _itemsKey = 'items';
  static const _cachedAtKey = 'cachedAt';

  final Box<dynamic> box;

  @override
  Future<void> cacheUsers(List<UserModel> users) {
    return box.put(_cacheKey, {
      _cachedAtKey: DateTime.now().millisecondsSinceEpoch,
      _itemsKey: users.map((user) => user.toJson()).toList(),
    });
  }

  @override
  List<UserModel> getCachedUsers() {
    final raw = box.get(_cacheKey);
    if (raw is List) {
      return _fromItems(raw);
    }
    if (raw is Map) {
      return _fromItems(raw[_itemsKey]);
    }
    return [];
  }

  @override
  Future<void> clearCache() {
    return box.clear();
  }

  List<UserModel> _fromItems(dynamic items) {
    if (items is! List) {
      return [];
    }
    return items.whereType<Map>().map(UserModel.fromJson).toList();
  }
}
