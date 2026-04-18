// lib/models/chat_model.dart
class ChatModel {
  final String id;
  final String? name;
  final bool isGroup;
  final List<String> memberIds;
  final List<String>? memberNames;
  final List<String?>? memberAvatars;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? avatarUrl;

  const ChatModel({
    required this.id,
    this.name,
    this.isGroup = false,
    required this.memberIds,
    this.memberNames,
    this.memberAvatars,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.avatarUrl,
  });

  factory ChatModel.fromJson(Map<String, dynamic> j) => ChatModel(
    id:             j['id'] as String,
    name:           j['name'] as String?,
    isGroup:        (j['is_group'] as bool?) ?? false,
    memberIds:      List<String>.from(j['member_ids'] as List? ?? []),
    memberNames:    j['member_names'] != null
        ? List<String>.from(j['member_names'] as List)
        : null,
    memberAvatars:  j['member_avatars'] != null
        ? List<String?>.from(j['member_avatars'] as List)
        : null,
    lastMessage:    j['last_message'] as String?,
    lastSenderId:   j['last_sender_id'] as String?,
    lastMessageAt:  j['last_message_at'] != null
        ? DateTime.tryParse(j['last_message_at'] as String)
        : null,
    unreadCount:    (j['unread_count'] as int?) ?? 0,
    avatarUrl:      j['avatar_url'] as String?,
  );

  // Get display name for a 1-on-1 chat (not current user's)
  String displayName(String currentUserId) {
    if (isGroup && name != null) return name!;
    if (memberNames != null) {
      final idx = memberIds.indexWhere((id) => id != currentUserId);
      if (idx >= 0 && idx < memberNames!.length) return memberNames![idx];
    }
    return name ?? 'Chat';
  }

  String? displayAvatar(String currentUserId) {
    if (isGroup) return avatarUrl;
    if (memberAvatars != null) {
      final idx = memberIds.indexWhere((id) => id != currentUserId);
      if (idx >= 0 && idx < memberAvatars!.length) return memberAvatars![idx];
    }
    return avatarUrl;
  }
}
