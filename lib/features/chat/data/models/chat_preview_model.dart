import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPreviewModel {
  const ChatPreviewModel({
    required this.chatId,
    required this.peerId,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
  });

  final String chatId;
  final String peerId;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;

  factory ChatPreviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};
    final participants = (data['participants'] as List<dynamic>? ?? [])
        .map((id) => id.toString())
        .toList();
    final peerId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final rawTime = data['lastMessageTime'];
    return ChatPreviewModel(
      chatId: doc.id,
      peerId: peerId,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: rawTime is Timestamp ? rawTime.toDate() : null,
    );
  }

  factory ChatPreviewModel.fromJson(Map<dynamic, dynamic> json) {
    final millis = json['lastMessageTime'];
    return ChatPreviewModel(
      chatId: json['chatId'] as String? ?? '',
      peerId: json['peerId'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageSenderId: json['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: millis is num
          ? DateTime.fromMillisecondsSinceEpoch(millis.toInt())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'peerId': peerId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
    };
  }

  ChatPreviewEntity toEntity() {
    return ChatPreviewEntity(
      chatId: chatId,
      peerId: peerId,
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageTime: lastMessageTime,
    );
  }
}
