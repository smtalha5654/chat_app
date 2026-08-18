import 'package:chat_app/core/constants/firestore_collections.dart';
import 'package:chat_app/core/error/exceptions.dart';
import 'package:chat_app/features/chat/data/models/chat_preview_model.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> watchMessages(String chatId);

  Stream<List<ChatPreviewModel>> watchChatPreviews(String userId);

  Future<List<ChatPreviewModel>> fetchChatPreviews(String userId);

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  });

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  });

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  static const _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _chats {
    return firestore.collection(FirestoreCollections.chats);
  }

  CollectionReference<Map<String, dynamic>> _messages(String chatId) {
    return _chats.doc(chatId).collection(FirestoreCollections.messages);
  }

  Query<Map<String, dynamic>> _chatsForUser(String userId) {
    return _chats.where('participants', arrayContains: userId);
  }

  List<ChatPreviewModel> _previewsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String userId,
  ) {
    return snapshot.docs
        .map(
          (doc) => ChatPreviewModel.fromFirestore(doc, currentUserId: userId),
        )
        .where((preview) => preview.peerId.isNotEmpty)
        .toList();
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MessageModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<ChatPreviewModel>> watchChatPreviews(String userId) {
    return _chatsForUser(userId).snapshots().map(
      (snapshot) => _previewsFromSnapshot(snapshot, userId),
    );
  }

  @override
  Future<List<ChatPreviewModel>> fetchChatPreviews(String userId) async {
    try {
      final snapshot = await _chatsForUser(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
      return _previewsFromSnapshot(snapshot, userId);
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not load chats');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final chatRef = _chats.doc(chatId);
      final messageRef = _messages(chatId).doc();
      final batch = firestore.batch();
      batch.set(messageRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isEdited': false,
      });
      batch.set(chatRef, {
        'participants': [senderId, receiverId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageId': messageRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit().timeout(
        _timeout,
        onTimeout: () {
          throw const NetworkException('Request timed out. Please try again.');
        },
      );
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not send message');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    try {
      await _messages(chatId)
          .doc(messageId)
          .update({'text': text, 'isEdited': true})
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
      await _syncChatPreview(chatId);
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not edit message');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _messages(chatId)
          .doc(messageId)
          .delete()
          .timeout(
            _timeout,
            onTimeout: () {
              throw const NetworkException(
                'Request timed out. Please try again.',
              );
            },
          );
      await _syncChatPreview(chatId);
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _fromFirebase(e, 'Could not delete message');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> _syncChatPreview(String chatId) async {
    final chatRef = _chats.doc(chatId);
    final latest = await _messages(chatId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get()
        .timeout(
          _timeout,
          onTimeout: () {
            throw const NetworkException('Request timed out. Please try again.');
          },
        );
    if (latest.docs.isEmpty) {
      await chatRef.set({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'lastMessageId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    final message = MessageModel.fromFirestore(latest.docs.first);
    await chatRef.set({
      'lastMessage': message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'lastMessageSenderId': message.senderId,
      'lastMessageId': message.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Never _fromFirebase(FirebaseException e, String fallback) {
    if (e.code == 'unavailable') {
      throw const NetworkException();
    }
    if (e.code == 'permission-denied') {
      throw ServerException('$fallback. Check Firestore rules.');
    }
    final message = e.message;
    if (message == null || message.isEmpty) {
      throw ServerException('$fallback (${e.code}).');
    }
    throw ServerException('$fallback (${e.code}): $message');
  }
}
