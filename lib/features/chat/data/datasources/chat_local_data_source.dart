import 'package:chat_app/features/chat/data/models/chat_preview_model.dart';
import 'package:hive/hive.dart';

abstract class ChatLocalDataSource {
  Future<void> cachePreviews(String userId, List<ChatPreviewModel> previews);

  List<ChatPreviewModel> getCachedPreviews(String userId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  ChatLocalDataSourceImpl({required this.box});

  static const boxName = 'chat_previews';
  static const _previewsKey = 'previews';
  static const _userIdKey = 'userId';

  final Box<dynamic> box;

  @override
  Future<void> cachePreviews(String userId, List<ChatPreviewModel> previews) {
    return box.put(_previewsKey, {
      _userIdKey: userId,
      'items': previews.map((preview) => preview.toJson()).toList(),
    });
  }

  @override
  List<ChatPreviewModel> getCachedPreviews(String userId) {
    final raw = box.get(_previewsKey);
    if (raw is! Map) {
      return [];
    }
    if (raw[_userIdKey] != userId) {
      return [];
    }
    final items = raw['items'];
    if (items is! List) {
      return [];
    }
    return items.whereType<Map>().map(ChatPreviewModel.fromJson).toList();
  }
}
