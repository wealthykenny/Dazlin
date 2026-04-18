// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;
  static bool get hasToken => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kWorkerBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw ApiException(data['error'] ?? 'Request failed');
    return data;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$kWorkerBase$path'), headers: _headers);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw ApiException(data['error'] ?? 'Request failed');
    return data;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResult> signUp({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    final data = await _post('/api/auth/signup', {
      'email': email,
      'username': username,
      'password': password,
      if (displayName != null) 'display_name': displayName,
    });
    return AuthResult.fromJson(data);
  }

  static Future<AuthResult> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final data = await _post('/api/auth/signin', {
      'email_or_username': emailOrUsername,
      'password': password,
    });
    return AuthResult.fromJson(data);
  }

  static Future<AuthResult> googleAuth({
    required String idToken,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    final data = await _post('/api/auth/google', {
      'id_token':    idToken,
      'email':       email,
      'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return AuthResult.fromJson(data);
  }

  static Future<UserModel> getMe() async {
    final data = await _get('/api/users/me');
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Chats ─────────────────────────────────────────────────────────────────

  static Future<List<ChatModel>> getChats() async {
    final data = await _get('/api/chats');
    final list = data['chats'] as List? ?? [];
    return list.map((e) => ChatModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ChatModel> createDirectChat(String targetUserId) async {
    final data = await _post('/api/chats/direct', {'target_user_id': targetUserId});
    return ChatModel.fromJson(data['chat'] as Map<String, dynamic>);
  }

  static Future<ChatModel> createGroupChat(String name, List<String> memberIds) async {
    final data = await _post('/api/chats/group', {
      'name':       name,
      'member_ids': memberIds,
    });
    return ChatModel.fromJson(data['chat'] as Map<String, dynamic>);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  static Future<List<MessageModel>> getMessages(String chatId, {int limit = 50, String? before}) async {
    final q = '?limit=$limit${before != null ? '&before=$before' : ''}';
    final data = await _get('/api/chats/$chatId/messages$q');
    final list = data['messages'] as List? ?? [];
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? replyToId,
  }) async {
    final data = await _post('/api/chats/$chatId/messages', {
      'content':     content,
      'type':        type,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return MessageModel.fromJson(data['message'] as Map<String, dynamic>);
  }

  static Future<void> markRead(String chatId) async {
    await _post('/api/chats/$chatId/read', {});
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  static Future<List<UserModel>> searchUsers(String query) async {
    final data = await _get('/api/users/search?q=${Uri.encodeComponent(query)}');
    final list = data['users'] as List? ?? [];
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    await _post('/api/users/me/update', {
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
  }

  static Future<void> setOnline(bool online) async {
    try {
      await _post('/api/users/me/presence', {'is_online': online});
    } catch (_) {}
  }
}

class AuthResult {
  final String token;
  final UserModel user;

  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    token: j['token'] as String,
    user:  UserModel.fromJson(j['user'] as Map<String, dynamic>),
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
