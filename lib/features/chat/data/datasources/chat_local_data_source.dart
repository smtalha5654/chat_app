import 'package:chat_app/features/chat/data/models/chat_preview_model.dart';
import 'package:hive/hive.dart';

abstract class ChatLocalDataSource {
  Future<void> cachePreviews(String userId, List<ChatPreviewModel> previews);

  List<ChatPreviewModel> getCachedPreviews(String userId);

  Future<void> clearCache();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  ChatLocalDataSourceImpl({required this.box});

  static const boxName = 'chat_previews';
  static const _cacheKey = 'previews';
  static const _userIdKey = 'userId';
  static const _itemsKey = 'items';
  static const _cachedAtKey = 'cachedAt';

  final Box<dynamic> box;

  @override
  Future<void> cachePreviews(String userId, List<ChatPreviewModel> previews) {
    return box.put(_cacheKey, {
      _userIdKey: userId,
      _cachedAtKey: DateTime.now().millisecondsSinceEpoch,
      _itemsKey: previews.map((preview) => preview.toJson()).toList(),
    });
  }

  @override
  List<ChatPreviewModel> getCachedPreviews(String userId) {
    final raw = box.get(_cacheKey);
    if (raw is! Map) {
      return [];
    }
    if (raw[_userIdKey] != userId) {
      return [];
    }
    return _fromItems(raw[_itemsKey]);
  }

  @override
  Future<void> clearCache() {
    return box.clear();
  }

  List<ChatPreviewModel> _fromItems(dynamic items) {
    if (items is! List) {
      return [];
    }
    return items.whereType<Map>().map(ChatPreviewModel.fromJson).toList();
  }
}
