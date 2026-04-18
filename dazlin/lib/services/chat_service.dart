// lib/services/chat_service.dart
import 'dart:async';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  static final Map<String, StreamController<List<MessageModel>>> _msgControllers = {};
  static final Map<String, Timer> _msgTimers = {};
  static final StreamController<List<ChatModel>> _chatsController =
      StreamController<List<ChatModel>>.broadcast();

  static Timer? _chatsTimer;
  static List<ChatModel> _cachedChats = [];
  static final Map<String, List<MessageModel>> _cachedMessages = {};

  // ── Chats stream ──────────────────────────────────────────────────────────

  static Stream<List<ChatModel>> get chatsStream => _chatsController.stream;
  static List<ChatModel> get cachedChats => _cachedChats;

  static void startChatsPolling() {
    _fetchChats();
    _chatsTimer?.cancel();
    _chatsTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchChats());
  }

  static void stopChatsPolling() {
    _chatsTimer?.cancel();
    _chatsTimer = null;
  }

  static Future<void> _fetchChats() async {
    try {
      final chats = await ApiService.getChats();
      _cachedChats = chats;
      if (!_chatsController.isClosed) _chatsController.add(chats);
    } catch (_) {}
  }

  // ── Messages stream ───────────────────────────────────────────────────────

  static Stream<List<MessageModel>> messagesStream(String chatId) {
    if (!_msgControllers.containsKey(chatId)) {
      _msgControllers[chatId] = StreamController<List<MessageModel>>.broadcast();
    }
    return _msgControllers[chatId]!.stream;
  }

  static List<MessageModel> cachedMessages(String chatId) =>
      _cachedMessages[chatId] ?? [];

  static void startMessagesPolling(String chatId) {
    _fetchMessages(chatId);
    _msgTimers[chatId]?.cancel();
    _msgTimers[chatId] = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchMessages(chatId),
    );
  }

  static void stopMessagesPolling(String chatId) {
    _msgTimers[chatId]?.cancel();
    _msgTimers.remove(chatId);
  }

  static Future<void> _fetchMessages(String chatId) async {
    try {
      final msgs = await ApiService.getMessages(chatId);
      _cachedMessages[chatId] = msgs;
      final ctrl = _msgControllers[chatId];
      if (ctrl != null && !ctrl.isClosed) ctrl.add(msgs);
    } catch (_) {}
  }

  static Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? replyToId,
  }) async {
    final msg = await ApiService.sendMessage(
      chatId:    chatId,
      content:   content,
      type:      type,
      replyToId: replyToId,
    );
    // Optimistically append
    final list = List<MessageModel>.from(_cachedMessages[chatId] ?? [])..add(msg);
    _cachedMessages[chatId] = list;
    final ctrl = _msgControllers[chatId];
    if (ctrl != null && !ctrl.isClosed) ctrl.add(list);
    // Also refresh chats list for last message
    _fetchChats();
    return msg;
  }

  static void dispose() {
    stopChatsPolling();
    for (final t in _msgTimers.values) t.cancel();
    _msgTimers.clear();
    for (final c in _msgControllers.values) c.close();
    _msgControllers.clear();
  }
}
