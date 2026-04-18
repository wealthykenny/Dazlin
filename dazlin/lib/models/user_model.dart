// lib/models/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  String get name => displayName ?? username;

  String get initials {
    final n = name;
    if (n.isEmpty) return '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:          j['id'] as String,
    username:    j['username'] as String,
    email:       j['email'] as String,
    displayName: j['display_name'] as String?,
    avatarUrl:   j['avatar_url'] as String?,
    isOnline:    (j['is_online'] as bool?) ?? false,
    lastSeen:    j['last_seen'] != null
        ? DateTime.tryParse(j['last_seen'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'username':     username,
    'email':        email,
    'display_name': displayName,
    'avatar_url':   avatarUrl,
    'is_online':    isOnline,
    'last_seen':    lastSeen?.toIso8601String(),
  };
}
