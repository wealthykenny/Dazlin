// lib/models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String type; // text | image | sticker
  final DateTime createdAt;
  final bool isRead;
  final String? replyToId;
  final String? replyPreview;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
    this.replyToId,
    this.replyPreview,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id:           j['id'] as String,
    chatId:       j['chat_id'] as String,
    senderId:     j['sender_id'] as String,
    senderName:   j['sender_name'] as String?,
    senderAvatar: j['sender_avatar'] as String?,
    content:      j['content'] as String,
    type:         (j['type'] as String?) ?? 'text',
    createdAt:    DateTime.parse(j['created_at'] as String),
    isRead:       (j['is_read'] as bool?) ?? false,
    replyToId:    j['reply_to_id'] as String?,
    replyPreview: j['reply_preview'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'chat_id':      chatId,
    'sender_id':    senderId,
    'content':      content,
    'type':         type,
    'created_at':   createdAt.toIso8601String(),
    'is_read':      isRead,
    'reply_to_id':  replyToId,
    'reply_preview': replyPreview,
  };
}
